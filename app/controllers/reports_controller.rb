class ReportsController < ApplicationController

  # POST reports/item_count
  # POST reports/item_sum
  # POST reports/item_average
  # POST reports/item_list
  def show
    report = Services::Report.new()
    render json: report.__send__(params["report_name"], report_params.merge(user: current_user))
  rescue Services::Report::ArgumentsError => e
    Rails.logger.error e
    render json: {error: e.message}, status: :unprocessable_content
  rescue => e
    Rails.logger.error e
    render json: {error: "Unable to render report"}, status: :internal_server_error
  end

  def report_params
    params.permit(:start_at, :end_at, :register_id, :group_by_period, :timezone, group_by: [])
  end
end
