class ConnectionsController < ApplicationController
  
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
    if connection.update
      render json: connection
    else
      render_bad_request connection
    end
  end

  def destroy
    connection.destroy
  end

  private

  def connection
    @_connection = Connection.find(params[:id])
  end

  def connection_params
    params.permit(:from, :to, :transform)
  end
end
