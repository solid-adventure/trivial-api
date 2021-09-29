class StatsController < ApplicationController

  def hourly
    render json: App.hourly_stats(current_user)
  end

  def daily
    render json: App.daily_stats(current_user)
  end

  def weekly
    render json: App.weekly_stats(current_user)
  end

end
