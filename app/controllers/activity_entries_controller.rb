class ActivityEntriesController < ApplicationController
  MAX_RESULTS = 100

  def index
    render json: activity.map(&:activity_attributes).to_json
  end

  def create
    @entry = ActivityEntry.new(activity_entry_params)
    @entry.user = current_user
    @entry.app = current_user.apps.kept.find_by_name!(params[:app_id])
    @entry.save!
    render status: :created, json: @entry.activity_attributes
  end

  private

  def activity
    @activity ||= app_activity.limit(limit).order(created_at: :desc)
  end

  def app_activity
    if params[:app_id].present?
      current_user.apps.find_by_name!(params[:app_id]).activity_entries
    else
      current_user.activity_entries
    end
  end

  def limit
    [[(params[:limit] || MAX_RESULTS).to_i, 1].max, MAX_RESULTS].min
  end

  def activity_entry_params
    params.permit(:activity_type, :source, :status, :duration_ms, payload: {}, diagnostics: {})
  end
end
