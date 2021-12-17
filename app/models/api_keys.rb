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

  def refresh!(key, path)
    assert_was_valid_for_app!(key)
    new_key = issue!
    update_credentials!(key, path, new_key)
    new_key
  end

  def assert_valid!(key)
    payload, header = JWT.decode key, public_key, true, {algorithm: ALGORITHM}
    payload['app']
  end

  def self.assert_valid!(key)
    ApiKeys.new.assert_valid!(key)
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

  def assert_valid_path!(path)
    raise "Invalid credentials path" unless /^[0-9A-Za-z]+\.[0-9A-Za-z]+$/.match?(path)
  end

  def assert_was_valid_for_app!(key)
    payload, header = JWT.decode key, public_key, true, {verify_expiration: false, algorithm: ALGORITHM}
    raise "Invalid app id" unless payload['app'] == app.name
  end

  def private_key
    OpenSSL::PKey::RSA.new ENV['JWT_PRIVATE_KEY']
  end

  def public_key
    private_key.public_key
  end

end
