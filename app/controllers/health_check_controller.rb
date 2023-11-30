class HealthCheckController < ApplicationController
  skip_before_action :authenticate_user!

  rescue_from(Exception) { render head: :service_unavailable }

  def show
    render head: :ok
  end
end
