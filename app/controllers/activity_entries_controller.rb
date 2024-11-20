class ActivityEntriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:update, :create_from_request]
  before_action :set_activity_entries, only: %i[index search]

  def index
    authorize! :index, ActivityEntry

    search = params[:search] ? JSON.parse(params[:search]) : []
    if search.any?
      @activity_entries = if search_on_payload?(search)
                            # adding a limit when payload is present in the search creates an inefficient query plan
                            # plucking ids then limiting on the id only search avoids this
                            ids = ActivityEntry.search(@activity_entries, search).pluck(:id)
                            ActivityEntry.where(id: ids)
                          else
                            ActivityEntry.search(@activity_entries, search)
                          end
    end

    @activity_entries = @activity_entries.order(id: :desc).limit(limit)
    render json: @activity_entries, status: :ok, adapter: :attributes, each_serializer: ActivityEntryIndexSerializer
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
  end

  def search
    authorize! :index, ActivityEntry
    search = if params[:search].is_a?(String)
      JSON.parse(params[:search])
    elsif params[:search].is_a?(Array)
      params[:search]
    end
    raise 'search required' unless search.any?

    @activity_entries = ActivityEntry.search(@activity_entries, search).limit(search_result_limit).order(id: :desc)

    render json: @activity_entries, status: :ok , adapter: :attributes, each_serializer: ActivityEntryMemberSerializer
  rescue StandardError => exception
    Rails.logger.error "Search failed: #{exception.message}"
    render_errors(exception, status: :unprocessable_entity)
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

    date_cutoff = Time.now - 7.days
    grouped_stats = app.activity_entries
      .where(activity_type: 'request', created_at: date_cutoff..)
      .group("created_at::date", :status)
      .count

    formatted_stats = {}
    grouped_stats.each do |(date, status), count|
      formatted_stats[date] ||= { date: date, count: {} }
      formatted_stats[date][:count][status] = count
    end

    render json: formatted_stats.values.to_json
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
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

    # delete the version paths after successfully migrating activity_entry_payload_keys v2 in prod
    if view_version(params[:col]) == 1
      keys = if params[:path]
               ActivityEntry.get_keys_from_path(params[:col], params[:path], current_app.activity_entries)
             else
               materialized_key_view_for(params[:col])
                 .where(app_id: current_app.id)
                 .pluck(:keys)
             end
    else # this is the new version to use after successful migration
      primary_key = params[:path] ? params[:path].gsub(/[{}]/, '') : nil
      keys = if primary_key
               materialized_key_view_for(params[:col])
                 .where(app_id: current_app.id)
                 .where(primary_key: primary_key)
                 .where('secondary_key IS NOT NULL')
                 .pluck(:secondary_key)
             else
               materialized_key_view_for(params[:col])
                 .where(app_id: current_app.id)
                 .distinct
                 .pluck(:primary_key)
             end
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
  # These can likely be unified in a future pass
  # The 20 limit is likely much too low after a misdiagnosed missing index
  MAX_RESULTS = 20
  MAX_SEARCH_RESULTS = 1000

  def search_result_limit
    [[(params[:limit] || MAX_SEARCH_RESULTS).to_i, 1].max, MAX_SEARCH_RESULTS].min
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

  def set_activity_entries
    @activity_entries = if params[:app_id].present?
                          current_user.associated_apps.find_by_name(params[:app_id]).activity_entries
                        else
                          current_user.associated_activity_entries
                        end
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

  # this will be deleted when the activity_entry_payload_key v2 is rolled out successfully in prod
  def view_version(col)
    view = materialized_key_view_for(col)
    view.reset_column_information # this ensures fresh column info after a migration
    if view.column_names.include?('keys')
      return 1
    else
      return 2
    end
  end

  def search_on_payload?(search)
    search.each do |hash|
      return true if hash['c'] == 'payload'
    end
    false
  end
end
