class StagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :authenticate_stage_user!, only: [:show]
  before_action :authenticate_stage_manager!, only: [:create, :update, :destroy]

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

  def board
    @_board = Board.find(params[:board_id])
  end

  def flow
    @_flow = board.flows.find(params[:flow_id])
  end

  def stage
    @_stage = flow.stages.find(params[:id])
  end

  def stage_params
    params.permit(:flow_id, :name, :subcomponents)
  end

  def authenticate_stage_user!
    authenticate_item_user!(board)
  end

  def authenticate_stage_manager!
    authenticate_item_manager!(board, 'You cannot change this stage!')
  end
end
