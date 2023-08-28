class CredentialsBase

  class InvalidPatch < StandardError
    def initialize
      super("Incorrect value or path")
    end
  end

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

  def can_patch_path?(path, current_value)
    return false unless allowed_patch_paths.any?{|p| path_matches?(p, path)}
    return false unless current_value == value_at_path(secret_value, path)
    true
  end

  def patch_path!(path, current_value, new_value)
    raise InvalidPatch unless can_patch_path?(path, current_value)
    set_value_at_path(secret_value, path, new_value)
    save!
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

  def allowed_patch_paths
    []
  end

  def path_matches?(spec, path)
    return false unless spec.length == path.length
    for i in 0..spec.length-1
      return false unless spec[i] == '*' || spec[i] == path[i]
    end
    true
  end

  def value_at_path(obj, path)
    path.inject(obj){|obj, step| obj.try(:[], step)}
  end

  def set_value_at_path(obj, path, val)
    parent = value_at_path(obj, path[0..-2])
    parent.try(:[]=, path[-1], val)
  end

  def aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

  def self.aws_client
    Aws::SecretsManager::Client.new
  end

end
