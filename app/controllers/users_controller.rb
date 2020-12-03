class UsersController < ApplicationController
  before_action :authenticate_admin!
  before_action :validate_user_params!, only: [:update]

  def index
    render json: User.all
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render_bad_request user
    end
  end

  def show
    render json: user
  end

  def update
    if user.update(user_params)
      render json: user
    else
      render_bad_request user
    end
  end

  def destroy
    if user.team_manager?
      render_unprocessable 'You cannot delete a team manager!'
    else
      user.destroy
    end
  end

  private

  def user
    @_user ||= User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password, :team_id, :role, :approval)
  end

  def validate_user_params!
    if user.team_manager?
      if user_params.key?(:team_id) && user_params[:team_id].to_i != user.team_id
        render_errors ['You can not change team for a manager']
      elsif user_params.key?(:role) && user_params[:role] != user.role
        render_errors ['You can not change role for a manager']
      end
    end
  end
end
