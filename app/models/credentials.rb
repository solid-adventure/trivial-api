class Credentials

  attr_accessor :app, :name, :arn, :secret_value

  def initialize(attrs = nil)
    attrs = (attrs || {}).stringify_keys
    @app = attrs['app']
    @name = attrs['name']
    @arn = attrs['arn']
    @secret_value = attrs['secret_value']
  end

  def new_record?
    arn.blank?
  end

  def save!
    if new_record?
      create!
    else
      update!
    end
  end

  def create!
    res = aws_client.create_secret name: name, secret_string: secret_value_json
    @arn = res.arn
    add_credential_policy!
  end

  def add_credential_policy!
    aws_client.put_resource_policy secret_id: name, resource_policy: default_policy.to_json
  end

  def default_policy
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


  def update!
    aws_client.put_secret_value secret_id: name, secret_string: secret_value_json
  end

  def destroy!
    unless new_record?
      aws_client.delete_secret secret_id: name, force_delete_without_recovery: true
    end
  end

  def self.exists?(criteria = {})
    criteria = criteria.stringify_keys
    aws_client.describe_secret secret_id: criteria['name']
    true
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    false
  end

  def self.find_by_app_and_name!(app, name)
    secret = aws_client.get_secret_value secret_id: name
    self.new(
      app: app,
      name: secret.name,
      arn: secret.arn,
      secret_value: ActiveSupport::JSON.decode(secret.secret_string)
    )
  end

  def self.find_or_build_by_app_and_name(app, name)
    find_by_app_and_name!(app, name)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    self.new app: app, name: name, secret_value: {}
  end

  private

  def secret_value_json
    secret_value.to_json
  end

  def aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

  def self.aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

end
