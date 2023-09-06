# frozen_string_literal: true

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pagy::Backend

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid_record
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from CanCan::AccessDenied, with: :render_unauthorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit :sign_up, keys: %i[name email password team_id]
    devise_parameter_sanitizer.permit :account_update, keys: %i[redirect_url email]
  end

  def authenticate_admin!
    render_unauthorized 'You are not a admin user' unless current_user.admin?
  end

  def render_unauthorized(message = 'Unauthorized!')
    render_errors [message], status: :unauthorized
  end

  def render_unprocessable(message = 'Unprocessable entity!')
    render_errors [message], status: :unprocessable_entity
  end

  def render_bad_request(object)
    render_errors object.errors.full_messages
  end

  def render_errors(errors, status: :bad_request)
    render json: { errors: errors }, status: status
  end

  def render_invalid_record(err)
    render json: { errors: err.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_not_found(err)
    render status: :not_found
  end


  def auth_key
    auth = request.headers['Authorization']
    match = /^Bearer\s+(\S+)/i.match(auth)
    match.try(:[], 1)
  end

  def authenticate_app!
    @current_app_id =  ApiKeys.assert_valid!(auth_key)
  rescue => e
    logger.error "Could not authorize API key: #{e}"
    render_unauthorized
  end

  def current_app
    @current_app = App.find_by_name!(@current_app_id)
  end
end
