class TeamsController < ApplicationController
  before_action :authenticate_admin!, only: [:index]
  before_action :authenticate_individual!, only: [:create]
  before_action :authenticate_team_manager!, only: %i[update destroy]
  before_action :authenticate_team_member!, only: %i[show]

  def index
    render json: Team.all, include: []
  end

  def create
    ActiveRecord::Base.transaction do
      team = Team.new(team_params)
      unless team.save
        render_bad_request team
        raise ActiveRecord::Rollback
      end
      unless current_user.update(team: team, role: 'manager', approval: 'approved')
        render_bad_request current_user
        raise ActiveRecord::Rollback
      end
      render json: team, status: :created
    rescue
    end
  end

  def show
    render json: team
  end

  def update
    if team.update(team_params)
      render json: team
    else
      render_bad_request team
    end
  end

  def destroy
    team.destroy
  end

  private

  def team
    @_team ||= Team.find(params[:id])
  end

  def team_params
    params.permit(:name)
  end

  def authenticate_individual!
    if current_user.team.present?
      render_unauthorized 'You belong to a team already'
    end
  end

  def authenticate_team_manager!
    unless current_user.admin? || (current_user.team_manager? && current_user.team == team)
      render_unauthorized 'You cannot update this team'
    end
  end

  def authenticate_team_member!
    if !current_user.admin? && (current_user.team != team || !current_user.approved)
      render_unauthorized 'You do not have permission'
    end
  end
end
