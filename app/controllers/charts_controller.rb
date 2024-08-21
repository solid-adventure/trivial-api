class ChartsController < ApplicationController
  before_action :set_dashboard
  before_action :set_chart, only: %i[show update destroy]

  # GET /dashboards/1/charts
  def index
    authorize! :read, @dashboard
    render json: @dashboard.charts
  end

  # GET /dashboard/1/charts/1
  def show
    authorize! :read, @chart
    render json: @chart
  end

  # POST dashboards/1/charts
  def create
    @chart = Chart.new(chart_params)
    @chart.dashboard = @dashboard
    authorize! :create, @chart

    report_groups = if groups_params[:report_groups].present?
                      @chart.unalias_groups!(groups_params[:report_groups])
                    else
                      @chart.unaliased_groups()
                    end
    @chart.assign_attributes(report_groups)

    if @chart.save
      render json: @chart, status: :created
    else
      render json: @chart.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT dashboards/1/charts/1
  def update
    authorize! :update, @chart

    report_groups = @chart.unalias_groups!(groups_params[:report_groups]) if groups_params.present?
    if @chart.update(chart_params.merge(report_groups))
      render json: @chart
    else
      render json: @chart.errors, status: :unprocessable_entity
    end
  end

  # DELETE dashboards/1/charts/1
  def destroy
    authorize! :destroy, @chart
    if @chart.destroy
      render status: :ok
    else
      render json: @chart.errors, status: :unprocessable_entity
    end
  end

  private
    def set_dashboard
      @dashboard = Dashboard.find(params[:dashboard_id])
    end

    def set_chart
      @chart = @dashboard.charts.find(params[:id])
    end

    def chart_params
      params.require(:chart).permit(:register_id, :name, :chart_type, :color_scheme, :invert_sign, :report_period)
    end

    # this is an aliased parameter for several underlying chart columns
    def groups_params
      params.permit(report_groups: {})
    end
end
