class ApiKeysController < ApplicationController
  skip_before_action :authenticate_user!, only: [:update]

  def create
    render json: {api_key: app.api_keys.issue!}
  end

  def update
    render json: {api_key: app(false).api_keys.refresh!(auth_key, params[:path])}
  rescue ApiKeys::OutdatedKeyError
    render status: :conflict
  rescue => e
    logger.error "API key refresh failed - #{e}: #{e.backtrace.join("\n")}"
    render status: :unauthorized
  end

  private

  def app(for_user = true)
    if for_user
      @app ||= current_user.associated_apps.kept.find_by_name!(params[:app_id])
    else
      @app ||= App.kept.find_by_name!(params[:app_id])
    end
  end

end
