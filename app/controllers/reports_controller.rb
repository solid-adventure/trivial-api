class ReportsController < ApplicationController

  # POST reports/item_count
  # POST reports/item_sum
  # POST reports/item_average
  # POST reports/item_list
  def show
    raise CanCan::AccessDenied unless current_user.associated_registers.pluck(:id).include? report_params[:register_id]
    report = Services::Report.new()
    render json: report.__send__(report_name, report_params)
  rescue ArgumentError => e
    Rails.logger.error e
    render json: {error: e.message}, status: :unprocessable_entity
  rescue => e
    Rails.logger.error e
    render json: {error: "Unable to render report"}, status: :internal_server_error
  end

  def report_params
    params.permit(
      :start_at,
      :end_at,
      :register_id,
      :invert_sign,
      :group_by_period,
      :timezone,
      group_by: [],
      search: [:c, :o, :p]
    )
  end

  ALLOWED_REPORTS = %w[ item_sum item_average item_count ].freeze
  def report_name
    unless ALLOWED_REPORTS.include? params["report_name"]
      raise ArgumentError, "unpermitted report: #{params[:report_name]}"
    end
    params["report_name"]
  end
end
