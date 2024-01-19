require 'env_handler'

class Role
  include EnvHandler

  AFTER_CREATE_DELAY = 1.5

  attr_accessor :name, :arn

  def initialize(attrs = nil)
    attrs = (attrs || {}).stringify_keys
    @name = attrs['name']
    @arn = attrs['arn']
  end

  def self.create!(attrs = nil)
    attrs = (attrs || {}).stringify_keys
    role = aws_client.create_role({
      assume_role_policy_document: ActiveSupport::JSON.encode(assume_role_policy),
      role_name: attrs['name']
    })

    aws_client.attach_role_policy({
      policy_arn: ENV['LAMBDA_POLICY_ARN'],
      role_name: role.role.role_name
    })

    # avoid a race condition that results if role is used immediately after creation
    sleep AFTER_CREATE_DELAY

    self.new name: role.role.role_name, arn: role.role.arn
  end

  private

  def self.aws_client
    aws_env_set?
    @aws_client ||= Aws::IAM::Client.new
  end

  def self.assume_role_policy
    {
      Version: '2012-10-17',
      Statement: [{
        Effect: 'Allow',
        Principal: {Service: 'lambda.amazonaws.com'},
        Action: 'sts:AssumeRole'
      }]
    }
  end

end
