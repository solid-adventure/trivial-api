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

shared_context "aws_role" do
  include_context "stubbed_env"

  let!(:iam_client_inst) { instance_double('Aws::IAM::Client') }
  let!(:iam_client) { class_double('Aws::IAM::Client').as_stubbed_const }
  let(:create_role_response) {
    OpenStruct.new({role: OpenStruct.new({
      role_name: 'examplerole',
      role_arn: 'examplearn'
    })})
  }

  before do
    allow(iam_client).to receive(:new).and_return(iam_client_inst)
    allow(iam_client_inst).to receive(:create_role).and_return(create_role_response)
    allow(iam_client_inst).to receive(:attach_role_policy).and_return(nil)
    stub_const('Role::AFTER_CREATE_DELAY', 0)
  end
end

shared_context "aws_env" do |klass|
  before do
    allow(klass).to receive(:aws_env_set?).and_return(nil)
    allow_any_instance_of(klass).to receive(:aws_env_set?).and_return(nil)
  end
end
