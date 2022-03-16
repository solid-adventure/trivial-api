require 'rails_helper'

describe App do

  describe "#daily_stats" do
    let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
    let(:user_app) { FactoryBot.create(:app, user: user) }
    let!(:success1) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app) }
    let!(:success2) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app) }
    let!(:failure1) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app, status: '404') }
    let(:stats) { App.daily_stats(user)[:stats].first[:stats] }

    it "returns a summary count of activity for the day" do
      expect(stats.inject(0){|sum,s| sum + s[:successes]}).to eql 2
      expect(stats.inject(0){|sum,s| sum + s[:failures]}).to eql 1
    end
  end

end
