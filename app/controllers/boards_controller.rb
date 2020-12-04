class BoardsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :authenticate_admin!, only: [:index]
  before_action :authenticate_board_user!, only: [:show]
  before_action :authenticate_board_manager!, only: [:update, :destroy]
  after_action { pagy_headers_merge(@pagy) if @pagy }, only: [:index]

  def index
    @pagy, boards = pagy(Board.all, items: 250)
    render json: boards, include: []
  end

  def create
    board = Board.new(board_params)
    board.owner = current_user
    if board.save
      render json: board, status: :created
    else
      render_bad_request board
    end
  end

  def show
    render json: board, include: []
  end
     
  def update         
    if board.update(board_params)
      render json: board
    else
      render_bad_request board
    end
  end           

  def destroy
    board.destroy
  end

  private

  def board
    @_board ||= Board.find_by_slug!(params[:id])
  end

  def board_params
    params.permit(:name, :access_level)
  end

  def authenticate_board_user!
    unless  board.free?||
            current_user.present? && current_user.admin? ||
            current_user.present? && board.trivial? ||
            board.users.exists?(id: current_user.id) ||
            board.team? && board.owner.team.present? &&  board.owner.team == current_user.team && current_user.approved? ||
            board.owner == current_user

        raise ActiveRecord::RecordNotFound
    end
  end

  def authenticate_board_manager!
    render_unauthorized 'You cannot change this board!' unless current_user.admin? || current_user == board.owner
  end
end
