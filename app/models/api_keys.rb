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

  # Allow non-expiring api keys for apps to use in their environment variable settings. These
  # api keys will be used for retrieving credential sets required to run the app. These
  # cannot expire because the app has no way to update the environment variables for itself.
  def issue_non_expiring_key!
    JWT.encode non_expiring_payload, private_key, ALGORITHM
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

  def non_expiring_payload
    {
      app: app.name,
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

end
