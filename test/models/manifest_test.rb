require 'test_helper'

class ManifestTest < ActiveSupport::TestCase
    def setup
        @manifest = Manifest.new
        @manifest.app_id = 'BrownShirt'
        @manifest.content = '{"x":1}'
        @manifest.user = User.create(name: 'bilbo', email: 'test@gmail.com', password: '12345678')
        @manifest.app = App.create(user: @manifest.user, owner: @manifest.user, name: 'BrownShirt')
        @manifest.save!
        @user2 = User.create(name: 'gandolf', email: 'gandolf@gmail.com', password: '12345678')
    end

    test 'valid manifest' do
        assert @manifest.valid?
    end

    test 'invalid without app_id' do
        @manifest.app_id = nil
        @manifest.valid?

        assert_equal @manifest.errors[:app_id], ["can't be blank"]
    end

    test 'invalid without content' do
        @manifest.content = nil
        @manifest.valid?

        assert_equal @manifest.errors[:content], ["can't be blank"]
    end

    test 'invalid without user_id' do
        @manifest.user_id = nil
        @manifest.valid?

        assert_equal @manifest.errors[:user_id], ["can't be blank"]
    end

    test 'content app id updates to app_id' do
        @manifest.set_content_app_id
        content = JSON.parse(@manifest.content)
        assert_equal content["app_id"], "BrownShirt"
    end

    test 'copy_to_app! updates app and user' do
        new_app = App.new(descriptive_name: "Hold Steady")
        new_app.user = @user2
        new_app.owner = @user2
        new_app.save!

        new_manifest = @manifest.copy_to_app!(new_app)
        assert_equal new_manifest.user, @user2
        assert_equal new_manifest.app, new_app

    end

end
