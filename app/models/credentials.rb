class Credentials < CredentialsBase

  ALLOWED_PATCH_PATHS = [
    %w(* * *)
  ].freeze

  attr_accessor :app

  def initialize(attrs = nil)
    super(attrs)
    attrs = (attrs || {}).stringify_keys
    @app = attrs['app']
  end

  def default_policy
    {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: {AWS: app.aws_role},
        Action: 'secretsmanager:GetSecretValue',
        Resource: arn
      }]
    }
  end


  def drafts
    secret_value['$drafts'] || {}
  end

  def draft_by_token(token)
    draft = drafts[token] || {'value' => {}}
    draft['value']
  end

  def add_draft(token, expires, value)
    all_drafts = drafts
    all_drafts[token] = {'expires' => expires.to_i, 'value' => value}
    secret_value['$drafts'] = all_drafts
  end

  def self.find_by_app_and_name!(app, name)
    secret = aws_client.get_secret_value secret_id: name
    self.new(
      app: app,
      name: secret.name,
      arn: secret.arn,
      secret_value: prune_drafts(ActiveSupport::JSON.decode(secret.secret_string))
    )
  end

  def self.find_or_build_by_app_and_name(app, name)
    find_by_app_and_name!(app, name)
  rescue Aws::SecretsManager::Errors::ResourceNotFoundException
    self.new app: app, name: name, secret_value: {}
  end

  protected

  def allowed_patch_paths
    ALLOWED_PATCH_PATHS
  end

  def secret_value_json
    self.class.prune_drafts(secret_value).to_json
  end

  def self.prune_drafts(secret)
    if secret.has_key?('$drafts')
      secret['$drafts'] = secret['$drafts'].filter{|k,v| v['expires'] > Time.now.to_i}
      secret.delete('$drafts') if secret['$drafts'].empty?
    end
    secret
  end

end
