class FlowsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :authenticate_flow_manager!,  only: [:create, :update, :destroy]
  before_action :authenticate_flow_user!, only: [:show]

  def create
    flow = Flow.new(flow_params)
    if flow.save
      render json: flow
    else
      render_bad_request flow
    end
  end

  def show
    render json: flow
  end

  def update
    if flow.update(flow_params)
      render json: flow
    else
      render_bad_request flow
    end
  end

  def destroy
    flow.destroy
  end

  private

  def board
    @_board = Board.find(params[:board_id])
  end

  def flow
    @_flow = board.flows.find(params[:id])
  end

  def flow_params
    params.permit(:board_id, :name)
  end

  def authenticate_flow_user!
    authenticate_item_user!(board)
  end

  def authenticate_flow_manager!
    authenticate_item_manager!(board, 'You cannot change this flow!')
  end
end
