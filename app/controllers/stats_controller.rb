class StatsController < ApplicationController

  def hourly
    render json: App.hourly_stats(current_user)
  end

end
