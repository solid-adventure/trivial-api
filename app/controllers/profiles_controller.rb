class ProfilesController < ApplicationController
  def show
    render json: current_user
  end

  def update
    if current_user.update(profile_params)
      render json: current_user
    else
      render_bad_request  current_user
    end
  end

  private

  def profile_params
    params.permit(:name, :color_theme)
  end
end
