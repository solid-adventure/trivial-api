class CredentialsBase

  attr_accessor :name, :arn, :secret_value

  def initialize(attrs = nil)
    attrs = (attrs || {}).stringify_keys
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
    raise "Credential policy not configured"
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

  protected

  def secret_value_json
    secret_value.to_json
  end

  def aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

  def self.aws_client
    Aws::SecretsManager::Client.new
  end

end
