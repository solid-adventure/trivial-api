require 'test_helper'

class CredentialsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
    @app = App.create!(user: @user, descriptive_name: 'App', name: 'app')
  end

  test 'grants permission to the app\'s role' do
    Credentials.stub :find_by_app_and_name!, -> (a, n) { Credentials.new(app: a, name: n, secret_value: {}) } do
      assert_equal @app.credentials.name, 'credentials/app'
    end
  end
end
