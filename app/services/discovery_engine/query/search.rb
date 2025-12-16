module DiscoveryEngine::Query
  class Search
    DEFAULT_PAGE_SIZE = 10
    DEFAULT_OFFSET = 0
    DEFAULT_ORDER_BY = nil # not specifying an order_by means the results are ordered by relevance

    def initialize(
      query_params,
      user_agent: nil
    )
      @query_params = query_params
      @user_agent = user_agent

      Rails.logger.debug { "Instantiated #{self.class.name}: Query: #{discovery_engine_params}" }
    end

    def result_set
      ResultSet.new(
        results: response.results.map { Result.from_stored_document(_1.document.struct_data.to_h) },
        total: response.total_size,
        start: offset,
        suggested_queries:,
        discovery_engine_attribution_token: response.attribution_token,
      )
    end

  private

    attr_reader :query_params, :user_agent

    def response
      @response ||= begin
        search_result =
          Metrics::Exported.observe_duration(:vertex_search_request_duration) do
            DiscoveryEngine::Clients.search_service.search(discovery_engine_params)
          end

        search_result.response
      rescue Google::Cloud::DeadlineExceededError, Google::Cloud::InternalError => e
        Rails.logger.warn("#{self.class.name}: Did not get search results: '#{e.message}'")
        raise DiscoveryEngine::InternalError
      end
    end

    def discovery_engine_params
      if query_params[:disable_query_time_boosts].present?
        {
          query:,
          serving_config: serving_config.name,
          page_size:,
          offset:,
          order_by:,
          filter:,
          user_labels:,
        }.compact
      else
        {
          query:,
          serving_config: serving_config.name,
          page_size:,
          offset:,
          order_by:,
          filter:,
          boost_spec:,
          user_labels:,
        }.compact
      end
    end

    def query
      query_params[:q].presence || ""
    end

    def serving_config
      return ServingConfig.default if query_params[:serving_config].blank?

      ServingConfig.new(query_params[:serving_config])
    end

    def page_size
      query_params[:count].presence&.to_i || DEFAULT_PAGE_SIZE
    end

    def offset
      query_params[:start].presence&.to_i || DEFAULT_OFFSET
    end

    def order_by
      case query_params[:order].presence
      when "public_timestamp"
        "public_timestamp"
      when "-public_timestamp"
        "public_timestamp desc"
      when nil, "relevance", "popularity"
        # "relevance" and "popularity" behave differently on the previous search-api, but we can
        # treat them the same with Discovery Engine (as empty searches will default to a
        # popularity-ish order anyway and we don't have an explicit popularity option available).
        DEFAULT_ORDER_BY
      else
        # This helps us spot clients that are sending unexpected values and probably should continue
        # to use the previoius search-api instead of this API.
        Rails.logger.warn("Unexpected order_by value: #{query_params[:order].inspect}")
        DEFAULT_ORDER_BY
      end
    end

    def filter
      Filters.new(query_params).filter_expression
    end

    def boost_spec
      {
        condition_boost_specs: [
          *news_recency_boost_specs,
          *best_bets_boost_specs,
        ],
      }
    end

    def news_recency_boost_specs
      # Since we first created `NewsRecencyBoost`, Vertex AI Search has gained the equivalent
      # functionality natively. As of Mar 2025, we are AB testing this new feature on the `variant`
      # serving configuration, so we do not want to apply our custom boost if that is the serving
      # config used for the current search, as it would cause content to be boosted twice.
      #
      # TODO: Remove this method (and `NewsRecencyBoost` class) when we have successfully concluded
      # the AB test.
      return [] if serving_config == ServingConfig.variant

      NewsRecencyBoost.new.boost_specs
    end

    def best_bets_boost_specs
      @best_bets_boost_specs ||= BestBetsBoost.new(query).boost_specs
    end

    def suggested_queries
      # TODO: Highlighting isn't actually supported by Discovery Engine, and this _always_ returns a
      # single suggestion, but we need to do this for API compatibility with Finder Frontend.
      # Eventually this should be improved.
      return [] unless query_params[:suggest] == "spelling_with_highlighting"

      # Gotcha: Discovery Engine returns an empty string rather than null if there is no correction.
      return [] if response.corrected_query.blank?

      [{
        text: response.corrected_query,
        highlighted: "<mark>#{response.corrected_query}</mark>",
      }]
    end

    def user_labels
      UserLabels.from_user_agent(user_agent).to_h
    end
  end
end
