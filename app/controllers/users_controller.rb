class UsersController < ApplicationController
  before_action :authenticate_admin!

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
      user.destroy
  end

  private

  def user
    @_user ||= User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password, :role, :approval)
  end
  
end
