class TeamsController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  before_action :authenticate_admin!, only: :create
  before_action :authenticate_team_managable!, only: %i[update destroy]

  def index
    render json: Team.all, include: []
  end

  # TODO: discuss if create is needed and when

  def create
    team = Team.new(team_params)

    if team.save
      render json: team, status: :created
    else
      render json: { errors: team.errors }, status: :unprocessable_entity
    end
  end

  # TODO: discuss permission of show team

  def show
    render json: team
  end

  def update
    if team.update(team_params)
      render json: team
    else
      render json: { errors: team.errors }, status: :unprocessable_entity
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

  def authenticate_team_managable!
    unless current_user.admin? || (current_user.team_manager? && current_user.team == team)
      render_unauthorized 'You cannot modify this team!'
    end
  end
end
