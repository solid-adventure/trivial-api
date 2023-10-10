require 'test_helper'

class CredentialsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
    @app = App.create!(user: @user, owner: @user, descriptive_name: 'App')
  end

  test 'grants permission to the app\'s role' do
    Credentials.stub :find_by_app_and_name!, -> (a, n) { Credentials.new(app: a, name: n, arn: "arn:x:#{n}", secret_value: {}) } do
      Role.stub :create!, -> (n) { Role.new(name: n[:name], arn: "arn:x:#{n[:name]}") } do
        assert_equal @app.aws_role,
          @app.credentials.default_policy[:Statement].first[:Principal][:AWS]
      end
    end
  end
end
