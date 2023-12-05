require 'test_helper'
# ActiveRecord::Base.logger = Logger.new(STDOUT)
class AbilityTest < ActiveSupport::TestCase
  def setup
    @user1 = User.create!(name: 'test', email: 'test@example.test', password: 'password')
    @user2 = User.create!(name: 'test2', email: 'test2@example.test', password: 'password2')
    @user3 = User.create!(name: 'test3', email: 'test3@example.test', password: 'password3')
    @customer = Customer.create(name: 'Acme', billing_email: 'ap@acme.com')

    @org1 = Organization.create(name: 'testorg1', billing_email: 'org1@example.test')

    OrgRole.create(organization: @org1, user: @user1, role: 'admin')

    @app_user1 = App.create(user: @user1, owner: @user1, descriptive_name: 'New App, User 1')
    @manifest_user1 = Manifest.create(user: @user1, owner: @user1, app_id: '123ABC', content: "{}", internal_app_id: @app_user1.id)

    @app_user2 = App.create(user: @user2, owner: @user2, descriptive_name: 'New App, User 2')
    @manifest_user2 = Manifest.create(user: @user2, owner: @user2, app_id: '456XYZ', content: "{}", internal_app_id: @app_user2.id)
    
    @app_user3 = App.create(user: @user3, owner: @user3, descriptive_name: 'New App, User 3')
    @manifest_user3 = Manifest.create(user: @user3, owner: @user3, app_id: '789MNO', content: "{}", internal_app_id: @app_user3.id)
    
    @app_org1 = App.create(user: @user1, owner: @org1, descriptive_name: 'New App, Org 1')
    @manifest_org1 = Manifest.create(user: @user1, owner: @org1, app_id: 'CBA321', content: "{}", internal_app_id: @app_org1.id)

    Permission.create(permissible: @app_user3, user: @user1, permit: Permission::READ_BIT)
    Permission.create(permissible: @manifest_user3, user: @user1, permit: Permission::READ_BIT)
  end
  # ruby -I test test/models/ability_test.rb 

  test 'undefined user has no apps' do
    ability = Ability.new(nil)
    assert_equal [], App.accessible_by(ability)
  end


  test 'user can read any associated resources' do
    apps = @user1.associated_apps
    manifests = @user1.associated_manifests
    ability = Ability.new(@user1)
  
    apps.each do |app|
      assert ability.can? :read, app
    end
    manifests.each do |manifest|
      assert ability.can? :read, manifest
    end
  end

  test 'user cannot access unassociated resources' do
    ability = Ability.new(@user1)

    assert_not ability.can? :read, @app_user2
    assert_not ability.can? :read, @manifest_user2
  end

  test 'user has all abilities for owned resources' do
    ability = Ability.new(@user1)
    
    assert ability.can? :manage, @app_user1
    assert ability.can? :grant, @app_user1
    assert ability.can? :revoke, @app_user1
    assert ability.can? :transfer, @app_user1

    assert ability.can? :manage, @manifest_user1
    assert ability.can? :grant, @manifest_user1
    assert ability.can? :revoke, @manifest_user1
    assert ability.can? :transfer, @manifest_user1
  end

  test 'user has all abilities for resources owned by orgs they are admin of' do
    ability = Ability.new(@user1)
    
    assert ability.can? :manage, @app_org1
    assert ability.can? :grant, @app_org1
    assert ability.can? :revoke, @app_org1
    assert ability.can? :transfer, @app_org1

    assert ability.can? :manage, @manifest_org1
    assert ability.can? :grant, @manifest_org1
    assert ability.can? :revoke, @manifest_org1
    assert ability.can? :transfer, @manifest_org1
  end

  test 'user only has permitted abilites for permitted resources' do
    ability = Ability.new(@user1)

    assert ability.can? :read, @app_user3
    assert_not ability.can? :update, @app_user3
    assert_not ability.can? :destroy, @app_user3
    assert_not ability.can? :grant, @app_user3
    assert_not ability.can? :revoke, @app_user3
    assert_not ability.can? :transfer, @app_user3

    assert ability.can? :read, @manifest_user3
    assert_not ability.can? :update, @manifest_user3
    assert_not ability.can? :destroy, @manifest_user3
    assert_not ability.can? :grant, @manifest_user3
    assert_not ability.can? :revoke, @manifest_user3
    assert_not ability.can? :transfer, @manifest_user3

    Permission.create(permissible: @app_user3, user: @user1, permit: Permission::GRANT_BIT)
    Permission.create(permissible: @manifest_user3, user: @user1, permit: Permission::REVOKE_BIT)
    assert ability.can? :grant, @app_user3
    assert ability.can? :revoke, @manifest_user3
  end
end
