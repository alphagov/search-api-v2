RSpec.describe DiscoveryEngine::Query::Search do
  subject(:search) { described_class.new(query_params, client:) }

  let(:client) { double("SearchService::Client", search: search_return_value) }
  let(:filters) { double(filter_expression: "filter-expression") }

  let(:query_params) { { q: "garden centres" } }

  let(:expected_boost_specs) do
    [{ boost: 0.2,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(628905600i,*)" },
     { boost: 0.05,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(621644400i,628905600e)" },
     { boost: -0.5,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(503280000i,597974400e)" },
     { boost: -0.75,
       condition: "content_purpose_supergroup: ANY(\"news_and_communications\") AND public_timestamp: IN(*,503280000e)" }]
  end

  before do
    allow(DiscoveryEngine::Query::Filters).to receive(:new).and_return(filters)
  end

  around do |example|
    Timecop.freeze(Time.zone.local(1989, 12, 13)) do
      example.run
    end
  end

  describe "#result_set" do
    context "when the search is successful" do
      subject!(:result_set) { search.result_set }

      let(:search_return_value) { double(response: search_response) }
      let(:search_response) do
        double(
          total_size: 42,
          attribution_token: "footobar",
          results:,
          corrected_query:,
        )
      end
      let(:results) do
        [
          double(document: double(struct_data: { title: "Louth Garden Centre" })),
          double(document: double(struct_data: { title: "Cleethorpes Garden Centre" })),
        ]
      end
      let(:corrected_query) { nil }

      it "calls the client with the expected parameters" do
        expect(client).to have_received(:search).with(
          serving_config: ServingConfig.default.name,
          query: "garden centres",
          offset: 0,
          page_size: 10,
          filter: "filter-expression",
          boost_spec: { condition_boost_specs: expected_boost_specs },
        )
      end

      it "returns a result set with the correct contents" do
        expect(result_set.discovery_engine_attribution_token).to eq("footobar")
        expect(result_set.start).to eq(0)
        expect(result_set.total).to eq(42)
        expect(result_set.results.map(&:title)).to eq([
          "Louth Garden Centre",
          "Cleethorpes Garden Centre",
        ])
      end

      context "when start and count are specified" do
        let(:query_params) { { q: "garden centres", start: "11", count: "22" } }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            serving_config: ServingConfig.default.name,
            query: "garden centres",
            offset: 11,
            page_size: 22,
            filter: "filter-expression",
            boost_spec: { condition_boost_specs: expected_boost_specs },
          )
        end

        it "returns the specified start value in the result set" do
          expect(result_set.start).to eq(11)
        end
      end

      context "when sorting by ascending public timestamp" do
        let(:query_params) { { q: "garden centres", order: "public_timestamp" } }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(order_by: "public_timestamp"),
          )
        end
      end

      context "when sorting by descending public timestamp" do
        let(:query_params) { { q: "garden centres", order: "-public_timestamp" } }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(order_by: "public_timestamp desc"),
          )
        end
      end

      context "when attempting to sort by an unexpected value" do
        let(:query_params) { { q: "garden centres", order: "foobarbaz" } }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_not_including(:order_by),
          )
        end
      end

      context "when no filter expression is returned" do
        let(:filters) { double(filter_expression: nil) }

        it "calls the client without a filter parameter" do
          expect(client).to have_received(:search).with(
            hash_not_including(:filter),
          )
        end
      end

      context "when searching for a query where the client returns a corrected query" do
        let(:corrected_query) { "graden crentres" }

        context "and the suggest parameter is 'spelling_with_highlighting'" do
          let(:query_params) { { q: "garden centres", suggest: "spelling_with_highlighting" } }

          it "returns the corrected query in the result set" do
            expect(result_set.suggested_queries).to eq([{
              text: "graden crentres",
              highlighted: "<mark>graden crentres</mark>",
            }])
          end
        end

        context "and the suggest parameter is not set" do
          let(:query_params) { { q: "garden centres" } }

          it "does not return a corrected query in the result set" do
            expect(result_set.suggested_queries).to be_empty
          end
        end
      end

      context "when searching for a query that has a single best bet defined" do
        # see test section in YAML config
        let(:query_params) { { q: "i want to test a single best bet" } }

        let(:expected_boost_specs) do
          super() + [{
            boost: 1,
            condition: 'link: ANY("/here/you/go")',
          }]
        end

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(boost_spec: { condition_boost_specs: expected_boost_specs }),
          )
        end
      end

      context "when searching for a query with a best bet in a different case and whitespace" do
        # see test section in YAML config
        let(:query_params) { { q: " I want to        TEST   a sInGlE best bET   " } }

        let(:expected_boost_specs) do
          super() + [{
            boost: 1,
            condition: 'link: ANY("/here/you/go")',
          }]
        end

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(boost_spec: { condition_boost_specs: expected_boost_specs }),
          )
        end
      end

      context "when searching for a query that has multiple best bets defined" do
        # see test section in YAML config
        let(:query_params) { { q: "i want to test multiple best bets" } }

        let(:expected_boost_specs) do
          super() + [{
            boost: 1,
            condition: 'link: ANY("/i-am-important","/i-am-also-important","/also-me")',
          }]
        end

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(boost_spec: { condition_boost_specs: expected_boost_specs }),
          )
        end
      end

      context "when a serving config is manually specified" do
        let(:query_params) { { q: "garden centres", serving_config: "preview" } }

        it "calls the client with the expected parameters" do
          expect(client).to have_received(:search).with(
            hash_including(serving_config: ServingConfig.new("preview").name),
          )
        end
      end

      context "when using the variant serving config" do
        let(:query_params) { { q: "garden centres", serving_config: "variant_search" } }

        it "does not include our manual news recency boosts" do
          expect(client).to have_received(:search).with(
            hash_including(
              serving_config: ServingConfig.variant.name,
              boost_spec: { condition_boost_specs: [] },
            ),
          )
        end
      end
    end

    context "when search fails" do
      let(:search_return_value) { double }

      before do
        allow(search_return_value)
          .to receive(:response)
          .and_raise(error)
        allow(Rails.logger).to receive(:warn)
      end

      context "and the error is actionable" do
        let(:error) { RangeError.new("integer 9999999990 too big") }

        it "returns the error" do
          expect { search.result_set }.to raise_error(error)
        end
      end

      context "and the error is a Google::Cloud::DeadlineExceededError" do
        let(:error) { Google::Cloud::DeadlineExceededError.new("Deadline error") }

        it "raises an error and logs it to the Rails logger" do
          expect { search.result_set }.to raise_error(DiscoveryEngine::InternalError)

          expect(Rails.logger).to have_received(:warn).with(
            "DiscoveryEngine::Query::Search: Did not get search results: 'Deadline error'",
          )
        end
      end

      context "and the error is a Google::Cloud::InternalError" do
        let(:error) { Google::Cloud::DeadlineExceededError.new("Internal error") }

        it "raises an error and logs it to the Rails logger" do
          expect { search.result_set }.to raise_error(DiscoveryEngine::InternalError)

          expect(Rails.logger).to have_received(:warn).with(
            "DiscoveryEngine::Query::Search: Did not get search results: 'Internal error'",
          )
        end
      end
    end
  end
end
