# frozen_string_literal: true

module Overrides
  class PasswordsController < DeviseTokenAuth::PasswordsController
    include PasswordStrengthValidator
    before_action :validate_password_strength!, only: [:update]
    
    private

    def redirect_options
      {
        allow_other_host: true
      }
    end
  end
end
