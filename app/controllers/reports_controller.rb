class ReportsController < ApplicationController

  # POST reports/item_count
  def item_count
    # render head: :ok
    # render json: @app, adapter: :attributes
    render json: {body: {title: "Count", count: rand(500..1000) }, statusCode: 200}
  end

end
