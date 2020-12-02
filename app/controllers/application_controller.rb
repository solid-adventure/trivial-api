# frozen_string_literal: true

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit :sign_up, keys: %i[name email password]
  end

  def authenticate_admin!
    render_unauthorized 'You are not a admin user' unless current_user.admin?
  end

  def render_unauthorized(message = 'Unauthorized!')
    render json: { errors: [message] }, status: :unauthorized
  end
end
