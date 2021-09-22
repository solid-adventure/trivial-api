require 'test_helper'

class CredentialsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
    @app = App.create!(user: @user, descriptive_name: 'App')
  end

  test 'grants permission to the app\'s role' do
    Role.stub :create!, -> (n) { Role.new(name: n[:name], arn: "arn:x:#{n[:name]}") } do
      assert_equal @app.aws_role,
        @app.credentials.default_policy[:Statement].first[:Principal][:AWS]
    end
  end
end
