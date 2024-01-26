module EnvHandler
  class MissingEnvVariableError < StandardError
  end

  # set any ENV variables that need to be checked here
  VARIABLES = %w[LAMBDA_POLICY_ARN AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY CLIENT_SECRET].freeze

  def self.included(base)
    base.extend(EnvMethods)
    base.include(EnvMethods)
  end

  module EnvMethods
    # creates check methods for each VARIABLE in downcased forms similar to "aws_region_set?"
    VARIABLES.each do |variable|
      define_method("#{variable.downcase}_set?") do
        raise MissingEnvVariableError, "#{variable} not set" if ENV[variable].blank?
      end
    end
    
    def aws_env_set?
      lambda_policy_arn_set?
      aws_region_set?
      aws_access_key_id_set?
      aws_secret_access_key_set?
    end
  end
end
