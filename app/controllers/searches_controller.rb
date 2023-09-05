class SearchesController < ApplicationController
  def show
    render json: {
      results: [],
      total: 0,
      start: 0,
    }
  end
end
