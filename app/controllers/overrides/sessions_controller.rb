# frozen_string_literal: true

module Overrides
  class SessionsController < DeviseTokenAuth::SessionsController
    skip_before_action :authenticate_user!, only: [:create]

    def create
      super
    end
  end
end
