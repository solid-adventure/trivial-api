shared_context "aws_credentials" do
  let(:stored_credentials) { '{}' }
  let(:credentials_response) {
    OpenStruct.new({name: 'credentials/x', arn: '::', secret_string: stored_credentials})
  }
  let!(:credentials_client_inst) { instance_double('Aws::SecretsManager::Client') }
  let!(:credentials_client) { class_double('Aws::SecretsManager::Client').as_stubbed_const }

  before do
    allow(credentials_client).to receive(:new).and_return(credentials_client_inst)
    allow(credentials_client_inst).to receive(:get_secret_value).and_return(credentials_response)
    allow(credentials_client_inst).to receive(:put_secret_value).and_return(nil)
    allow(credentials_client_inst).to receive(:delete_secret).and_return(nil)
  end
end
