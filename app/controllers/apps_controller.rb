class AppsController < ApplicationController

  def index
    render json: apps.to_json
  end

  def create
    @app = App.new(app_params)! user: current_user
    if @app.save
      render json: @app
    else
      render_bad_request app
    end
  end

  def show
    render json: app
  end

  def destroy
    app.discard!
    head :ok
  end

  def name_suggestion
    render json: Spicy::Proton.pair('_').camelize
  end
  private

  def app
    @app ||= current_user.apps.kept.find_by_name!(params[:id])
  end

  def apps
    if params[:include_deleted].present?
      @apps ||= current_user.apps.order(:name)
    else
      @apps ||= current_user.apps.kept.order(:name)
    end
  end

  def app_params
    params.permit(:hostname)
  end
end
