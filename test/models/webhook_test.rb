require 'test_helper'

class WebhookTest < ActiveSupport::TestCase
    def setup
        @webhook = Webhook.new
        @webhook.app_id = 'BrownShirt'
        @webhook.source = 'sample'
        @webhook.user = User.create(name: 'bilbo', email: 'test@gmail.com', password: '12345678')
        @webhook.save!
    end

    test 'valid webhook' do 
        assert @webhook.valid?
    end

    test 'invalid without app_id' do 
        @webhook.app_id = nil
        @webhook.valid?

        assert_equal @webhook.errors[:app_id], ["can't be blank"]
    end

    test 'invalid without source' do 
        @webhook.source = nil
        @webhook.valid?

        assert_equal @webhook.errors[:source], ["can't be blank"]
    end

    test 'invalid without user_id' do 
        @webhook.user_id = nil
        @webhook.valid?

        assert_equal @webhook.errors[:user_id], ["can't be blank"]
    end
end