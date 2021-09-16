class CredentialsController < ApplicationController

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

  private

  def app
    @app ||= current_user.apps.kept.find_by_name!(params[:app_id])
  end

end
