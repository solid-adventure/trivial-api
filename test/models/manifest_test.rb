require 'test_helper'

class ManifestTest < ActiveSupport::TestCase
    def setup
        @manifest = Manifest.new
        @manifest.app_id = 'BrownShirt'
        @manifest.content = '{"x":1}'
        @manifest.owner_id = 'Juan'
        @manifest.save!
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

    test 'invalid without owner_id' do 
        @manifest.owner_id = nil
        @manifest.valid?

        assert_equal @manifest.errors[:owner_id], ["can't be blank"]
    end
end