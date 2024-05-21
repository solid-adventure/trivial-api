# spec/models/manifest_spec.rb
require 'rails_helper'

describe Manifest do
  let(:user) { FactoryBot.create :user }
  let(:app) { FactoryBot.create :app, owner: user }
  let(:manifest_params) { { app_id: app.id, app: app, owner: user, content: "content" } }

  describe "create_activity_entry" do
    it "is called on save" do
      manifest = Manifest.new(manifest_params)

      expect(manifest).to receive(:create_activity_entry).and_call_original

      manifest.save!

      expect(manifest.app.activity_entries.count).to eq(1)
    end

    it "raises an error when explicitly by an instance" do
      manifest = FactoryBot.create :manifest
      expect {
        manifest.create_activity_entry
      }.to raise_error(NoMethodError)
    end
  end
end

