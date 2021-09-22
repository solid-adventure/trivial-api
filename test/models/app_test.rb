require 'test_helper'

class AppTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
      @user2 = User.create!(name: 'test2', email: 'test2@example.test', password: 'password2')
      @existing = App.create!(user: @user, descriptive_name: 'Existing App')
      @app = App.new(user: @user, descriptive_name: 'New App')
    end

    test 'passes validation with all required files' do
        assert @app.valid?
    end

    test 'automatically assigns name' do
      @app.valid?
      assert @app.name.present?
    end

    test 'automatically assigns port' do
      @app.valid?
      assert @app.port >= App::MINIMUM_PORT_NUMBER
    end

    test 'invalid without user' do
        @app.user_id = nil
        assert ! @app.valid?
    end

    test 'invalid with duplicate name' do
        @app.name = @existing.name
        assert ! @app.valid?
    end

    test 'invalid with duplicate port' do
      @app.port = @existing.port
        assert ! @app.valid?
    end

    test 'invalid without descriptive name' do
      @app.descriptive_name = nil
      @app.valid?

      assert_equal @app.errors[:descriptive_name], ["can't be blank", 'is too short (minimum is 3 characters)']
    end

    test 'assigns different roles to apps under different users' do
      Role.stub :create!, -> (n) { Role.new(name: n[:name], arn: "arn:x:#{n[:name]}") } do
        @other_app = App.new(user: @user2, descriptive_name: 'Other App')
        assert_not_equal @app.aws_role, @other_app.aws_role
      end
    end
  end