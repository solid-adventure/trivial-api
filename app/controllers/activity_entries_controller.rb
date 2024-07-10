class ActivityEntriesController < ApplicationController
  MAX_RESULTS = 20

  skip_before_action :authenticate_user!, only: [:update, :create_from_request]


  def index
    authorize! :index, ActivityEntry

    begin
      search = params[:search] ? JSON.parse(params[:search]) : []
      if search.any?
        @activity = ActivityEntry.search(app_activity, search)
      end
      render json: activity_for_index.map(&:activity_attributes_for_index).to_json
    rescue StandardError => exception
      render_errors(exception, status: :unprocessable_entity)
    end
  end

  def show
    activity_entry = ActivityEntry.find(params[:id])
    authorize! :read, activity_entry
    render json: activity_entry.activity_attributes.to_json
  end

  def create
    @app = current_user.associated_apps.kept.find_by_name!(params[:app_id])
    authorize! :update, @app

    @entry = ActivityEntry.new(activity_entry_params)
    @entry.owner = current_user
    @entry.app = @app
    @entry.save!
    render status: :created, json: @entry.activity_attributes
  end

  def create_from_request
    @entry = ActivityEntry.new(activity_entry_params)
    @entry.app = App.kept.find_by_name!(params[:app_id])
    @entry.owner = @entry.app.owner
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
    app = current_user.associated_apps.find_by_name!(params[:app_id])
    authorize! :read, app
    if app
      render json: ActivityEntry.chart_stats(app.id, 7)
    else
      render status: :not_found
    end
  end

  # POST /activity_entries/keys?col=col_name
  def refresh_keys
    raise 'col required to refresh a key_view' unless params[:col]
    raise "no view to refresh for #{col}" unless view = materialized_key_view_for(params[:col])

    view.refresh
    render status: :created
  end

  # GET /activity_entries/keys?app_id=123&col=col_name&path=path_value
  def keys
    raise 'app_id query string required for keys query' unless app_name = params[:app_id]
    raise CanCan::AccessDenied unless current_app = current_user.associated_apps.find_by(name: app_name)
    raise 'col query string required for keys query' unless params[:col]

    keys = if params[:path]
             ActivityEntry.get_keys_from_path(params[:col], params[:path], current_app.activity_entries)
           else
             materialized_key_view_for(params[:col])
               .where(app_id: current_app.id)
               .pluck(:keys)
           end

    render json: keys.to_json, status: :ok
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
  end

  def columns
    authorize! :index, ActivityEntry
    render json: ActivityEntry.get_columns(ActivityEntry::SEARCHABLE_COLUMNS).to_json, status: :ok
  end

  private
  def activity_for_index
    attrs = [:id, :owner_id, :owner_type, :app_id, :register_item_id, :activity_type, :status, :duration_ms, :payload, :created_at]
    @activity ||= app_activity
    @activity.select(attrs).limit(limit).order(created_at: :desc)
  end

  def activity
    @activity ||= app_activity.limit(limit).order(created_at: :desc)
  end

  def app_activity
    if params[:app_id].present?
      current_user.associated_apps.find_by_name(params[:app_id]).activity_entries
    else
      current_user.associated_activity_entries
    end
  end

  def limit
    [[(params[:limit] || MAX_RESULTS).to_i, 1].max, MAX_RESULTS].min
  end

  def activity_entry_params
    @activity_params = {}.merge(params.permit(:activity_type, :source, :status, :duration_ms, :register_item_id))
    @activity_params[:payload] = JSON.parse(request.body.read)["payload"]
    @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
    @activity_params
  end

  # Do not permit :payload or :activity_type on update, as it would re-write history
  def activity_entry_update_params
    @activity_params = {}.merge(params.permit(:status, :duration_ms, :register_item_id))
    @activity_params[:diagnostics] = JSON.parse(request.body.read)["diagnostics"]
    @activity_params
  end

  def updatable_entry
    @updatable_entry ||= ActivityEntry.updatable.find_by_update_id!(params[:id])
  end

  MATERIALIZED_KEY_VIEWS = {
    'payload' => ActivityEntryPayloadKey
  }.freeze

  def materialized_key_view_for(col)
    MATERIALIZED_KEY_VIEWS[col]
  end
end
