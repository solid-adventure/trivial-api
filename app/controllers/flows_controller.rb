class FlowsController < ApplicationController
  before_action :authenticate_flow_manager!,  only: [:update, :destroy]
  before_action :authenticate_flow_user!, only: [:show]
  after_action { pagy_headers_merge(@pagy) if @pagy }, only: [:index]

  def index
    @pagy, flows = pagy(Flow.all, items: 250)
    render json: flows, include: []
  end

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

  def flow
    @_flow = Flow.find(params[:id])
  end

  def flow_params
    params.permit(:name)
  end

  def authenticate_flow_user!
    unless  current_user.admin?
            current_user == flow.owner

        raise ActiveRecord::RecordNotFound
    end
  end

  def authenticate_flow_manager!
    render_unauthorized "You cannot change this flow!" unless current_user.admin? || current_user == flow.owner
  end
end
