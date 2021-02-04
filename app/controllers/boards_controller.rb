class BoardsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :authenticate_board_manager!, only: [:update, :destroy, :clone]
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def index
    @pagy, paginated_boards = pagy(boards, items: 250)
    render json: paginated_boards, include: []
  end

  def create
    board = Board.new(board_params)
    board.owner = current_user
    if board.save
      render json: board, include: {
        owner: [],
        flows: [:stages, :connections]
      }, status: :created
    else
      render_bad_request board
    end
  end

  def show
    render json: boards.find_by_slug!(params[:id]), include: {
      owner: [],
      flows: [:stages, :connections]
    }
  end
     
  def update
    if board.update(board_params)
      render json: board, include: {
        owner: [],
        flows: [:stages, :connections]
      }
    else
      render_bad_request board
    end
  end

  def destroy
    board.destroy
  end

  def clone
    new_board = Board.new(board.dup.attributes.except("slug"))
    new_board.owner = current_user

    board.flows.each do |flow|
      new_flow = new_board.flows.build(flow.dup.attributes)

      flow.stages.each do |stage|
        new_flow.stages.build(stage.dup.attributes)
      end
    end

    if new_board.save
      render json: new_board, include: {
        owner: [],
        flows: [:stages, :connections]
      }, status: :created
    else
      render_bad_request new_board
    end
  end

  private

  def boards
    @_boards ||= Board.available(current_user)
  end

  def board
    @_board ||= Board.find_by_slug!(params[:id])
  end

  def board_params
    params.permit(:name, :access_level, :contents)
  end

  def authenticate_board_manager!
    unless current_user.admin? || current_user == board.owner
      render_unauthorized 'You cannot change this board!' 
    end
  end
end
