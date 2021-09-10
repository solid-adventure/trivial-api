class CredentialsController < ApplicationController

  def show
    secret = aws_client.get_secret_value secret_id: secret_name
    render json: {credentials: ActiveSupport::JSON.decode(secret.secret_string)}
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    render json: {credentials: {}}
  end

  def update
    if params[:credentials].keys.empty?
      delete_credentials
    else
      save_credentials params[:credentials]
    end
    render json: {ok: true}
  end

  private

  def app
    @app ||= current_user.apps.kept.find_by_name!(params[:app_id])
  end

  def aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

  def secret_name
    "credentials/#{app.name}"
  end

  def delete_credentials
    aws_client.delete_secret secret_id: secret_name, force_delete_without_recovery: true
  end

  def save_credentials(credentials)
    payload = ActiveSupport::JSON.encode(credentials)
    if has_credentials?
      aws_client.put_secret_value secret_id: secret_name, secret_string: payload
    else
      aws_client.create_secret name: secret_name, secret_string: payload
    end
  end

  def has_credentials?
    aws_client.describe_secret secret_id: secret_name
    true
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    false
  end

end
