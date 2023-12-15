# frozen_string_literal: true

module Overrides
  class PasswordsController < DeviseTokenAuth::PasswordsController
    private

    def redirect_options
      {
        allow_other_host: true
      }
    end
  end
end
