class Credentials < ApplicationRecord
  encrypts :secret_value

  attr_accessor :app
  attr_accessor :user
  attr_accessor :customer
  class InvalidPatch < StandardError
    def initialize
      super("Incorrect value or path")
    end
  end

  def initialize(attrs = nil)
    super(attrs)
    attrs = (attrs || {}).stringify_keys
    @app = attrs['app']
    @user = attrs['user']
    @customer = attrs['customer']
  end

  def destroy!
    if owner_type == 'customer'
      errors.add(:base, "Cannot delete credential sets for customers.")
      throw :abort
    end
    super
  end

  def drafts
    secret_value['$drafts'] || {}
  end

  def draft_by_token(token)
    draft = drafts[token] || {'value' => {}}
    draft['value']
  end

  def add_draft(token, expires, value)
    all_drafts = drafts
    all_drafts[token] = {'expires' => expires.to_i, 'value' => value}
    secret_value['$drafts'] = all_drafts
  end

  def self.find_by_app_and_name!(app, name)
    secret = self.find_by(name: name, owner_type: 'app')
    if secret.nil?
      secret = aws_client.get_secret_value secret_id: name
      secret_value = ActiveSupport::JSON.decode(secret.secret_string)
      record = self.new(
        app: app,
        name: secret.name,
        owner_type: 'app',
        secret_value: prune_drafts(ActiveSupport::JSON.decode(secret.secret_string))
      )
    else
      secret.secret_value = prune_drafts(secret.secret_value)
      record = secret
    end
    record
  end

  def self.get_owner_type(owner)
    if owner.is_a?(User)
      'user'
    elsif owner.is_a?(Customer)
      'customer'
    else
      'user'
    end
  end

  def self.find_by_owner_and_name!(owner, owner_type,  name)
    secret = self.find_by(name: name, owner_type: owner_type)
    if secret.nil?
      secret = aws_client.get_secret_value secret_id: name
      secret_value = ActiveSupport::JSON.decode(secret.secret_string)
      record = self.new(
        user: owner,
        name: secret.name,
        owner_type: owner_type,
        secret_value: prune_drafts(secret_value)
      )
    else
      secret.secret_value = prune_drafts(secret.secret_value)
      record = secret
    end
    record
  end

  def self.find_or_build_by_app_and_name(app, name)
    find_by_app_and_name!(app, name)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    self.new app: app, owner_type: 'app', name: name, secret_value: {}
  end

  def self.find_or_build_by_owner_and_name(owner, name)
    owner_type = get_owner_type(owner)
    find_by_owner_and_name!(owner, owner_type, name)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    if owner_type == 'user'
      self.new user: owner, owner_type: owner_type, name: name, secret_value: {}
    else
      self.new customer: owner, owner_type: owner_type, name: name, secret_value: {}
    end
  end

  def can_patch_path?(path, current_value)
    puts 'secret', secret_value
    puts 'value', value_at_path(secret_value, path)
    puts 'current_value', current_value
    return false unless current_value == value_at_path(secret_value, path)
    true
  end

  def patch_path!(path, current_value, new_value)
    raise InvalidPatch unless can_patch_path?(path, current_value)
    set_value_at_path(secret_value, path, new_value)
    save!
  end

  protected

  def secret_value_json
    secret_value.to_json
  end

  def value_at_path(obj, path)
    path.inject(obj){|obj, step| obj.try(:[], step)}
  end

  def set_value_at_path(obj, path, val)
    parent = value_at_path(obj, path[0..-2])
    parent.try(:[]=, path[-1], val)
  end

  def secret_value_json
    self.class.prune_drafts(secret_value).to_json
  end

  def self.prune_drafts(secret)
    if secret.has_key?('$drafts')
      secret['$drafts'] = secret['$drafts'].filter{|k,v| v['expires'] > Time.now.to_i}
      secret.delete('$drafts') if secret['$drafts'].empty?
    end
    secret
  end

  def aws_client
    @aws_client ||= Aws::SecretsManager::Client.new
  end

  def self.aws_client
    Aws::SecretsManager::Client.new
  end

end
