class ReportsController < ApplicationController

  # POST reports/item_count
  # POST reports/item_sum
  # POST reports/item_average
  # POST reports/item_list
  def show
    begin
      report = Services::Report.new()
      render json: report.__send__(params["report_name"], report_params.merge(user: current_user))
    rescue => e
      Rails.logger.error e
      render json: {error: "Unable to render report"}, status: 500
    end
  end

  def report_params
    params.permit(:start_at, :end_at, :register_ids, group_by: [])
  end


end
