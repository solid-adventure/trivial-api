class MembersController < ApplicationController
  before_action :authenticate_team_manager!

  def index
    render json: team.users.pending, include: []
  end

  def show
    render json: team_member, include: []
  end

  def update
    if team_member.update(member_params)
      render json: team_member
    else
      render_bad_request team_member
    end
  end

  private

  def member_params
    params.permit(:approval)
  end

  def team
    @_team = current_user.team
  end

  def team_member
    @_team_member = team.users.find(params[:id])
  end

  def authenticate_team_manager!
    render_unauthorized "You are not a team manager!" unless current_user.team_manager?
  end
end
