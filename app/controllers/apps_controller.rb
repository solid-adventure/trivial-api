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

  private

  def app
    @app ||= current_user.apps.find(params[:id])
  end

  def apps
    @apps ||= current_user.apps.order(:name)
  end

end
