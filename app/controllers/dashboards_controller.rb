class DashboardsController < ApplicationController
  before_action :set_dashboard, only: %i[show update destroy]

  # GET /dashboards
  def index
    @dashboards = current_user.associated_dashboards
    render json: @dashboards
  end

  # GET /dashboards/1
  def show
    authorize! :read, @dashboard
    render json: @dashboard
  end

  # POST /dashboards
  def create
    @dashboard = Dashboard.new(create_dashboard_params)
    authorize! :create, @dashboard

    if @dashboard.save
      render json: @dashboard, status: :created, location: @dashboard
    else
      render json: @dashboard.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /dashboards/1
  def update
    authorize! :update, @dashboard
    if @dashboard.update(update_dashboard_params)
      render json: @dashboard
    else
      render json: @dashboard.errors, status: :unprocessable_entity
    end
  end

  # DELETE /dashboards/1
  def destroy
    authorize! :destroy, @dashboard
    if @dashboard.destroy
      render status: :ok
    else
      render json: @dashboard.errors, status: :unprocessable_entity
    end
  end

  private
    def set_dashboard
      @dashboard = Dashboard.find(params[:id])
    end

    def create_dashboard_params
      params.require(:dashboard).permit(:owner_type, :owner_id, :name, :dashboard_type)
    end

    def update_dashboard_params
      params.require(:dashboard).permit(:name, :dashboard_type)
    end
end
