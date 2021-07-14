class AppsController < ApplicationController

  def index
    render json: apps.to_json
  end

  def create
    @app = App.create! user: current_user
    render json: @app
  end

  def show
    render json: app
  end

  def destroy
    app.discard!
    head :ok
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

end
