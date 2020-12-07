class StagesController < ApplicationController
  before_action :authenticate_stage_user!, only: [:show]
  before_action :authenticate_stage_manager!, only: [:update, :destroy]

  def index
    render json: Stage.all
  end

  def create
    stage = Stage.new(stage_params)
    if stage.save
      render json: stage
    else
      render_bad_request stage
    end
  end

  def show
    render json: stage
  end

  def update
    if stage.update(stage_params)
      render json: stage
    else
      render_bad_request  stage
    end
  end

  def destroy
    stage.destroy
  end

  private

  def stage
    @_stage = Stage.find(params[:id])
  end

  def stage_params
    params.permit(:name, :subcomponents)
  end

  def authenticate_stage_manager!

  end

  def authenticate_stage_user!
    
  end
end
