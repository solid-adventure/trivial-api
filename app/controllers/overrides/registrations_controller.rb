# frozen_string_literal: true

module Overrides
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    skip_before_action :authenticate_user!, only: [:create]
  end
  protected 
  def after_update_path_for(resource)
    user_path(current_user)
  end
end
