class CredentialSetCredentials < CredentialsBase

  attr_accessor :user

  def initialize(attrs = nil)
    super(attrs)
    attrs = (attrs || {}).stringify_keys
    @user = attrs['user']
  end

  def default_policy
    {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: {AWS: user.aws_role},
        Action: 'secretsmanager:GetSecretValue',
        Resource: arn
      }]
    }
  end

  def self.find_by_user_and_name!(user, name)
    secret = aws_client.get_secret_value secret_id: name
    self.new(
      user: user,
      name: secret.name,
      arn: secret.arn,
      secret_value: ActiveSupport::JSON.decode(secret.secret_string)
    )
  end

  def self.find_or_build_by_user_and_name(user, name)
    find_by_user_and_name!(user, name)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    self.new user: user, name: name, secret_value: {}
  end

  protected

  def allowed_patch_paths
    [
      ['code_grant', 'access_token']
    ]
  end

end
