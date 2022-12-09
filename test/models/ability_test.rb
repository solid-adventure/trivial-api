require 'test_helper'
# ActiveRecord::Base.logger = Logger.new(STDOUT)
class AbilityTest < ActiveSupport::TestCase
    def setup
      @user1 = User.create!(name: 'test', email: 'test@example.test', password: 'password')
      @user2 = User.create!(name: 'test2', email: 'test2@example.test', password: 'password2')
      @customer = Customer.create(name: 'Acme', billing_email: 'ap@acme.com')
      @app_user1 = App.create(user: @user1, descriptive_name: 'New App')
      @app_user2 = App.create(user: @user2, descriptive_name: 'New App')
    end
    # ruby -I test test/models/ability_test.rb 

    test 'undefined user has no apps' do
      ability = Ability.new(nil)
      assert_equal [], App.accessible_by(ability)
    end


    test 'user has access to own apps' do
      apps = @user1.apps
      ability = Ability.new(@user1)
      assert_equal apps, apps.accessible_by(ability)
    end

    test 'user cannot acccess apps owned by others' do
      apps = App.all
      ability = Ability.new(@user1)
      assert_equal @user2.apps.length, 1
      assert_equal @user2.apps.accessible_by(ability).length, 0
    end

    test 'user can access other apps owned by the same customer account' do
      @customer.users << @user1
      @customer.users << @user2
      apps = App.where(user_id: [@user1.id, @user2.id])
      ability = Ability.new(@user1)
      assert_equal apps.pluck(:id), apps.accessible_by(ability).pluck(:id)
    end

    test 'user cannot access apps owned by a customer account they are not a member of' do
      @customer.users << @user1
      apps = App.accessible_by(Ability.new(@user1))
      assert_not_includes apps.pluck(:id), @app_user2.id
    end

    test 'new user with default role has no apps' do
      default = User.create!(name: 'default', email: 'default@example.com', password: 'password')
      assert_not_equal default.id, nil
      apps = App.accessible_by(Ability.new(default))
      assert_equal [], apps.pluck(:id)
    end

    test 'admin can access all apps' do
      skip("Pending support for admin abilities in UI")
      admin = User.create!(name: 'admin', email: 'admin@example.com', password: 'password', role: 'admin')
      assert_not_equal admin.id, nil
      apps = App.accessible_by(Ability.new(admin))
      assert_equal App.all.pluck(:id), apps.pluck(:id)
    end

  end