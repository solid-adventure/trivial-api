require 'test_helper'

class AppTest < ActiveSupport::TestCase
    def setup
      ENV['LAMBDA_POLICY_ARN'] = 'arn:aws:iam::aws:policy/service-role/FakeRole'
      ENV['AWS_REGION'] = 'us-east-1'
      ENV['AWS_ACCESS_KEY_ID'] = '987FAKEKEY'
      ENV['AWS_SECRET_ACCESS_KEY'] = '123FAKEKEY'

      @user = User.create!(name: 'test', email: 'test@example.test', password: 'password')
      @user2 = User.create!(name: 'test2', email: 'test2@example.test', password: 'password2')
      @existing = App.create!(owner: @user, descriptive_name: 'Existing App')
      @app = App.new(owner: @user, descriptive_name: 'New App')
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

    test 'invalid without owner' do
        @app.owner_id = nil
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

    test 'invalid with duplicate descriptive name' do
      @app.descriptive_name = @existing.descriptive_name
      @app.valid?
      assert_equal @app.errors[:descriptive_name], ["has already been taken"]
    end

    test 'valid with duplicate descriptive across users' do
      @app.descriptive_name = @existing.descriptive_name
      @app.owner = @user2
      assert @app.valid?
    end

    test 'assigns different roles to apps under different users' do
      Role.stub :create!, -> (n) { Role.new(name: n[:name], arn: "arn:x:#{n[:name]}") } do
        @other_app = App.new(owner: @user2, descriptive_name: 'Other App')
        assert_not_equal @app.aws_role, @other_app.aws_role
      end
    end

    test 'copies into same user account when no user provided' do
      new_app = @app.copy!(nil, @app.descriptive_name + ' Copy')
      new_app.valid?
      assert_not_equal @app.name, new_app.name
      assert_equal @app.owner, new_app.owner
    end

    test 'copies into new user account' do
      new_app = @app.copy!(@user2, @app.descriptive_name + ' Copy')
      new_app.valid?
      assert_equal new_app.owner, @user2
    end

    test 'copy includes manifest' do
      manifest = Manifest.new(app_id: @existing.name, internal_app_id: @existing.id, owner: @user, content: {app_id: @existing.name}.to_json)
      assert manifest.valid?
      @existing.manifests << manifest
      @existing.save!
      new_app = @existing.copy!(nil, @app.descriptive_name + ' Copy')
      assert_equal @existing.manifests.size, 1
      assert new_app.manifests.size, 1
    end

  end
