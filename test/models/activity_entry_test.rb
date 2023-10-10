require 'test_helper'

class ActivityEntryTest < ActiveSupport::TestCase
  def setup
    @app = App.new
    @app.user = User.create(name: 'bilbo', email: 'bilbo@example.test', password: '12345678')
    @app.owner = @app.user
    @app.descriptive_name = "Bilbo's App"
    @app.save!

    @entry = ActivityEntry.new
    @entry.app = @app
    @entry.activity_type = 'request'
    @entry.source = 'sample'
    @entry.user = @app.user
    @entry.save!
  end

  test 'valid entry' do
    assert @entry.valid?
  end

  test 'invalid without app_id' do
    @entry.app_id = nil
    @entry.valid?

    assert_equal @entry.errors[:app], ["must exist"]
  end

  test 'invalid without source' do
    @entry.source = nil
    @entry.valid?

    assert_equal @entry.errors[:source], ["can't be blank"]
  end

  test 'invalid without user_id' do
    @entry.user_id = nil
    @entry.valid?

    assert_equal @entry.errors[:user], ["must exist"]
  end
end
