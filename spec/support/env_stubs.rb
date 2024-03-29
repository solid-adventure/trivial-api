shared_context "stubbed_env" do
  let(:lambda_policy_arn) { 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole' }
  let(:jwt_private_key) { OpenSSL::PKey::RSA.new(2048).to_pem }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('LAMBDA_POLICY_ARN').and_return(lambda_policy_arn)
    allow(ENV).to receive(:[]).with('JWT_PRIVATE_KEY').and_return(jwt_private_key)
  end
end
