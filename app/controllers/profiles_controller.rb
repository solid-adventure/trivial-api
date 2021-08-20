class ProfilesController < ApplicationController
  before_action :check_current_user!, only: :update
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
    params.permit(:name, :team_id, :color_theme)
  end

  def check_current_user!
    if params[:team_id].present? && current_user.team_id != params[:team_id] && !current_user.member?
      render_unprocessable "You cannot change your team!"
    end
  end

  def make_pending
    current_user.pending! if current_user.saved_changes[:team_id].present?
  end
end
