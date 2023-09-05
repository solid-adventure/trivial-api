class ApiKeys

  class OutdatedKeyError < StandardError; end

  ALGORITHM = 'RS256'
  DURATION = 1.week

  attr_accessor :app

  def initialize(attrs = nil)
    attrs = (attrs || {}).stringify_keys
    @app = attrs['app']
  end

  def issue!
    JWT.encode payload, private_key, ALGORITHM
  end

  ## Issue a non-expiring key with permissions to all resources. Use with care.
  # key = ApiKeys.issue_client_key!
  def issue_client_key!
    key_id = SecureRandom.hex(15)
    payload = {key_id: key_id}
    key_access_token = JWT.encode payload, private_key, ALGORITHM
    return {
      key_id: key_id,
      key_access_token: key_access_token
    }
  end

  # ApiKeys.assert_client_key_valid!(key_access_token)
  def assert_client_key_valid!(key_access_token)
    payload, header = JWT.decode key_access_token, public_key, true, {algorithm: ALGORITHM}
    raise "Invalid Client Key" unless payload["key_id"] && valid_client_keys.include?(payload["key_id"])
  end

  def valid_client_keys
    keys = ENV['CLIENT_KEYS'] || ""
    return keys.split(',').map(&:strip)
  end

  def refresh!(key, path)
    assert_was_valid_for_app!(key)
    new_key = issue!
    update_credentials!(key, path, new_key)
    new_key
  end

  def refresh_in_credential_set!(credential_set, key, path)
    assert_was_valid_for_app!(key)
    new_key = issue!
    update_credential_set!(credential_set, key, path, new_key)
    new_key
  end

  def assert_valid!(key)
    payload, header = JWT.decode key, public_key, true, {algorithm: ALGORITHM}
    payload['app']
  end

  def decode_ignore_expiration(key)
    JWT.decode key, public_key, true, {verify_expiration: false, algorithm: ALGORITHM}
  end

  def self.assert_valid!(key)
    ApiKeys.new.assert_valid!(key)
  end

  def self.for_key!(key)
    payload, header = ApiKeys.new.decode_ignore_expiration(key)
    ApiKeys.new(app: App.find_by_name!(payload['app']))
  end

  private

  def payload
    {
      app: app.name,
      exp: DURATION.from_now.to_i
    }
  end

  # allows updating the credentials value at path if the correct current value is provided
  def update_credentials!(old_key, path, new_key)
    assert_valid_path! path
    section, item = path.split('.')
    credentials = app.credentials
    credentials.secret_value[section] = {} if credentials.secret_value[section].nil?
    raise OutdatedKeyError if credentials.secret_value[section][item] != old_key
    credentials.secret_value[section][item] = new_key
    credentials.save!
  end

  # allows updating the value in a credential set if the correct current value is provided
  def update_credential_set!(credential_set, old_key, path, new_key)
    credentials = credential_set.credentials
    raise OutdatedKeyError if credentials.secret_value[path] != old_key
    credentials.secret_value[path] = new_key
    credentials.save!
  end

  def assert_valid_path!(path)
    raise "Invalid credentials path" unless /^[0-9A-Za-z]+\.[0-9A-Za-z]+$/.match?(path)
  end

  def assert_was_valid_for_app!(key)
    payload, header = decode_ignore_expiration(key)
    raise "Invalid app id" unless payload['app'] == app.name
  end

  def private_key
    OpenSSL::PKey::RSA.new ENV['JWT_PRIVATE_KEY']
  end

  def public_key
    private_key.public_key
  end

  def self.issue_client_key!
    ApiKeys.new().issue_client_key!
  end

  def self.assert_client_key_valid!(key_access_token)
    ApiKeys.new().assert_client_key_valid!(key_access_token)
  end

end
