class CredentialsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:patch]
  before_action :authenticate_app!, only: [:patch]

  def show
    render json: {credentials: app.credentials.secret_value}
  end

  def update
    if params[:credentials].keys.empty?
      app.credentials.destroy!
    else
      app.credentials.secret_value = params[:credentials]
      app.credentials.save!
    end
    render json: {ok: true}
  end

  def patch
    current_app.credentials.patch_path!(
      params[:path],
      params[:credentials][:current_value],
      params[:credentials][:new_value]
    )
    render json: {ok: true}
  rescue => e
    logger.error "Failed to patch credentials: #{e}"
    render status: 400, json: {ok: false, error: e.message}
  end

  private

  def app
    @app ||= current_user.apps.kept.find_by_name!(params[:app_id])
  end

end
