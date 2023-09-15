class AppPermitsController < ApplicationController
  before_action :set_app_permit, only: %i[ show update destroy ]

  # GET /app_permits
  def index
    @app_permits = AppPermit.all

    render json: @app_permits
  end

  # GET /app_permits/1
  def show
    render json: @app_permit
  end

  # POST /app_permits
  def create
    @app_permit = AppPermit.new(app_permit_params)

    if @app_permit.save
      render json: @app_permit, status: :created, location: @app_permit
    else
      render json: @app_permit.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /app_permits/1
  def update
    if @app_permit.update(app_permit_params)
      render json: @app_permit
    else
      render json: @app_permit.errors, status: :unprocessable_entity
    end
  end

  # DELETE /app_permits/1
  def destroy
    @app_permit.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_app_permit
      @app_permit = AppPermit.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def app_permit_params
      params.fetch(:app_permit, {})
    end
end
