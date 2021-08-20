# frozen_string_literal: true

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pagy::Backend

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit :sign_up, keys: %i[name email password team_id]
  end

  def authenticate_admin!
    render_unauthorized 'You are not a admin user' unless current_user.admin?
  end

  def authenticate_item_user!(board)
    unless  Board.available(current_user).exists?(id: board.id)
      raise ActiveRecord::RecordNotFound
    end
  end

  def authenticate_item_manager!(board, message)
    unless  current_user.admin? ||
            current_user == board.owner ||
            board.owner.team == current_user.team && board.secret? && current_user.approved?
      render_unauthorized message
    end
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
end
