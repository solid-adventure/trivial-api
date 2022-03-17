shared_context "app_proxy_requests" do
  let(:app_status_code) { '200' }
  let(:app_status_message) { 'OK' }
  let(:app_response) {
    OpenStruct.new({code: app_status_code, message: app_status_message})
  }

  before do
    allow(ActivityEntry).to receive(:post).and_return(app_response)
  end
end
