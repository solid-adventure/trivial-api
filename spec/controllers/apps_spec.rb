require 'rails_helper'

RSpec.describe AppsController, :type => :controller do

  def login
    request.headers.merge!('access-token': access_token)
    request.headers.merge!(client: client)
    request.headers.merge!(expiry: expiry)
    request.headers.merge!(uid: uid)
  end

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let(:client) { user.tokens.keys.first }
  let(:access_token) { user.tokens[client]["token_unhashed"] }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  it "returns unauthorized without a user" do
    get :index, format: :json
    expect(response).to have_http_status(:unauthorized)
  end

  context "logged in user" do

    before do
      login
    end

    it "returns a users apps" do
      app = FactoryBot.create(:app, user: user)
      get :index, format: :json
      data = JSON.parse(response.body)
      expect(data.map { |a| a["id"] }).to eq [app.id]
      expect(response).to have_http_status(:success)
    end
  end

  context "tagged apps" do

    let!(:tagged_app) { FactoryBot.create(:app, user: user) }
    let!(:tag) { FactoryBot.create(:tag, taggable: tagged_app, context: 'color', name: 'blue') }

    before do
      login
    end

    it "returns the tagged app if no tagged_with params are present" do
      get :index, format: :json
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data.map { |a| a["id"] }).to include tagged_app.id
    end

    it "returns the tagged app when matching tagged_with params are present" do
      params = { tagged_with: [{'color': 'blue'}].to_json }
      get :index, format: :json, params: params
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data.map { |a| a["id"] }).to include tagged_app.id
    end


    it "does not return the tagged app when non-matching tagged_with params are present" do
      params = { tagged_with: [{'color': 'red'}].to_json }
      get :index, format: :json, params: params
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data.map { |a| a["id"] }).not_to include tagged_app.id
    end



  end

end