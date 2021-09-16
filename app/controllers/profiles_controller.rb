class ProfilesController < ApplicationController
  after_action  :make_pending, only: :update

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

  def make_pending
    current_user.pending! if current_user.saved_changes[:team_id].present?
  end
end
