class ActivityEntriesController < ApplicationController
  MAX_RESULTS = 100

  def index
    authorize! :index, ActivityEntry
    render json: activity.map(&:activity_attributes).to_json
  end

  def create
    authorize! :create, ActivityEntry
    @entry = ActivityEntry.new(activity_entry_params)
    @entry.user = current_user
    @entry.app = current_user.apps.kept.find_by_name!(params[:app_id])
    @entry.save!
    render status: :created, json: @entry.activity_attributes
  end

  def stats
    app = App.accessible_by(Ability.new(current_user)).find_by_name!(params[:app_id])
    authorize! :stats, app
    if app
      render json: ActivityEntry.chart_stats(app, 7)
    else
      render status: :not_found
    end
  end


  private

  def activity
    @activity ||= app_activity.limit(limit).order(created_at: :desc)
  end

  def app_activity
    if params[:app_id].present?
      App.accessible_by(Ability.new(current_user)).find_by_name(params[:app_id]).activity_entries
    else
      ActivityEntry.accessible_by(Ability.new(current_user)).all
    end
  end

  def limit
    [[(params[:limit] || MAX_RESULTS).to_i, 1].max, MAX_RESULTS].min
  end

  def activity_entry_params
      @activity_params = {}.merge(params.permit(:activity_type, :source, :status, :duration_ms))
      @activity_params[:payload] = params[:payload]
      @activity_params[:diagnostics] = params[:diagnostics]
      @activity_params
  end
end
