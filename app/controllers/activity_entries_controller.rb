class ActivityEntriesController < ApplicationController
  MAX_RESULTS = 100

  skip_before_action :authenticate_user!, only: [:update, :create_from_request]


  def index
    authorize! :index, ActivityEntry
    render json: activity_for_index.map(&:activity_attributes_for_index).to_json
  end

  def show
    activity_entry = ActivityEntry.find(params[:id])
    authorize! :read, activity_entry
    render json: activity_entry.activity_attributes.to_json
  end

  def create
    authorize! :create, ActivityEntry
    @entry = ActivityEntry.new(activity_entry_params)
    @entry.user = current_user
    @entry.app = current_user.apps.kept.find_by_name!(params[:app_id])
    @entry.save!
    render status: :created, json: @entry.activity_attributes
  end

  def create_from_request
    @entry = ActivityEntry.new(activity_entry_params)
    @entry.app = App.kept.find_by_name!(params[:app_id])
    @entry.user_id = @entry.app.user_id
    @entry.activity_type = 'request'
    @entry.normalize_json
    @entry.save!
    render status: :created, json: @entry.legacy_attributes
  end

  def update
    updatable_entry.update!(activity_entry_update_params)
    render json: updatable_entry.activity_attributes
  end

  def send_new
    @app = App.kept.find_by_name!(params[:id])
    authorize! :read, @app
    @bodyPayload = JSON.parse(request.body.read)
    res = ActivityEntry.send_new @app, @bodyPayload["payload"].to_json
    render json: {status: res.code.to_i, message: res.message}
  end

  def resend
    activity_entry = ActivityEntry.find(params[:id])
    authorize! :read, activity_entry
    res = activity_entry.resend
    render json: {status: res.code.to_i, message: res.message}
  end

  def stats
    app = App.accessible_by(Ability.new(current_user)).find_by_name!(params[:app_id])
    authorize! :read, app
    if app
      render json: ActivityEntry.chart_stats(app.id, 7)
    else
      render status: :not_found
    end
  end


  private

  def activity_for_index
    attrs = [:id, :user_id, :app_id, :activity_type, :status, :duration_ms, :payload, :created_at]
    @activity ||= app_activity.select(attrs).limit(limit).order(created_at: :desc)
  end

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
      @activity_params[:payload] = JSON.parse(request.body.read)["payload"]
      @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
      @activity_params
  end

  # Do not permit :payload or :activity_type on update, as it would re-write history
  def activity_entry_update_params
    @activity_params = {}.merge(params.permit(:status, :duration_ms))
    @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
    @activity_params
  end

  def updatable_entry
    @updatable_entry ||= ActivityEntry.updatable.find_by_update_id!(params[:id])
  end

end
