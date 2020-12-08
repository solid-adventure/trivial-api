class ConnectionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :authenticate_connection_manager!,  only: [:create, :update, :destroy]
  before_action :authenticate_connection_user!, only: [:show]

  def create
    connection = Connection.new(connection_params)
    if connection.save
      render json: connection, status: :created
    else
      render_bad_request connection
    end
  end

  def show
    render json: connection
  end

  def update
    if connection.update(connection_params)
      render json: connection
    else
      render_bad_request connection
    end
  end

  def destroy
    connection.destroy
  end

  private

  def board
    @_board = Board.find(params[:board_id])
  end

  def flow
    @_flow = board.flows.find(params[:flow_id])
  end

  def connection
    @_connection = flow.connections.find(params[:id])
  end

  def connection_params
    params.permit(:flow_id, :from_id, :to_id, :transform)
  end

  def board
    @_board = Board.find(params[:board_id])
  end

  def authenticate_connection_user!
    authenticate_item_user!(board)
  end

  def authenticate_connection_manager!
    authenticate_item_manager!(board, 'You cannot change this connection!')
  end
end
