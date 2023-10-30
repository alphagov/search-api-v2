class SearchesController < ApplicationController
  def show
    render json: Query.new.result_set
  end
end
