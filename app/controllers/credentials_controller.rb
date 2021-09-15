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
      res = aws_client.create_secret name: secret_name, secret_string: payload
      add_credential_policy res.arn
    end
  end

  def has_credentials?
    aws_client.describe_secret secret_id: secret_name
    true
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    false
  end

  def add_credential_policy(arn)
    policy = ActiveSupport::JSON.encode(default_policy(arn))
    aws_client.put_resource_policy secret_id: secret_name, resource_policy: policy
  end

  def default_policy(arn)
    {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: {AWS: app.aws_role},
        Action: 'secretsmanager:GetSecretValue',
        Resource: arn
      }]
    }
  end

end
