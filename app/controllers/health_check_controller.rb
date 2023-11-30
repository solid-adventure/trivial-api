class HealthCheckController < ApplicationController
  rescue_from(Exception) { render head: :service_unavailable }

  def show
    render head: :ok
  end
end
