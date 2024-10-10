class AppsController < ApplicationController

  def index
    if params[:includes] && params[:includes].include?("manifest")
      render json: apps, adapter: :attributes, include: [:manifests]
    else
      render json: apps, adapter: :attributes
    end
  end

  def last_request
    authorize! :read, app

    activity_entry = app.activity_entries.where(
      activity_type: 'request',
      payload: last_request_params[:payload])
    .order('created_at DESC')
    .limit(1)&.first

    if activity_entry.nil?
      render json: {status: 404, error: "No request found for this payload"}
    else
      authorize! :read, activity_entry
      render json: activity_entry.activity_attributes.to_json
    end
  end

  def create
    @app = App.new(app_params)
    @app.owner = current_user
    @app.save!
    render json: @app, adapter: :attributes
  end

  def show
    authorize! :read, app
    render json: app, adapter: :attributes
  end

  def update
    authorize! :update, app
    app.update!(app_params)
    render json: app, adapter: :attributes
  end

  def copy
    authorize! :update, app
    app_copy = app.copy!(nil, params[:new_app_descriptive_name])
    render json: app_copy, adapter: :attributes
  end

  def tags
    authorize! :update, app
    tag = app.addTag!(params[:context], params[:name])
    render json: tag
  end

  def remove_tags
    authorize! :update, app
    app.removeTag!(params[:context], params[:name])
    render json: {status: 200}
  end

  def destroy
    authorize! :destroy, app
    app.discard!
    head :ok
  end

  def name_suggestion
    render json: {suggestion: App.new.name_suggestion}
  end

  def collection_activity_stats
    app_names = params[:app_names].to_s.split(',')
    raise 'Invalid app_names provided' unless app_names.any?

    app_id_names_map = App.where(name: app_names).pluck(:id, :name).to_h
    app_ids = app_id_names_map.keys
    raise CanCan::AccessDenied unless (current_user.associated_apps.pluck(:id) & app_ids).length == app_ids.length

    date_cutoff ||= Time.now.midnight - 7.days
    cache_cutoff = Time.now.midnight
    cached_app_activity_stats = cached_activity_for(app_ids, app_id_names_map, date_cutoff, cache_cutoff)
    todays_app_activity_stats = uncached_activity_for(app_ids, app_id_names_map, cache_cutoff)

    app_activity_stats = merge_activity_stats(cached_app_activity_stats, todays_app_activity_stats)
    render json: app_activity_stats.to_json, status: :ok
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
  end

  def activity_stats
    authorize! :read, app

    app_id_names_map = { app.id => app.name }
    date_cutoff ||= Time.now.midnight - 7.days
    cache_cutoff = Time.now.midnight
    cached_app_activity_stats = cached_activity_for([app.id], app_id_names_map, date_cutoff, cache_cutoff)
    todays_app_activity_stats = uncached_activity_for([app.id], app_id_names_map, cache_cutoff)

    app_activity_stats = merge_activity_stats(cached_app_activity_stats, todays_app_activity_stats)

    render json: app_activity_stats.to_json
  rescue StandardError => exception
    render_errors(exception, status: :unprocessable_entity)
  end

  private

  def app
    @app ||= App.kept.find_by_name(params[:id])
  end

  def apps
    @apps ||= current_user.associated_apps
    @apps = @apps.find_by_all_tags(tagged_with_params) if tagged_with_params.present?
    if params[:include_deleted].present?
      @apps.order(:descriptive_name)
    else
      @apps.kept.order(:descriptive_name)
    end
  end

  def tagged_with_params
    params[:tagged_with].present? ? JSON.parse(params[:tagged_with]) : nil
  end

  def app_params
    params.permit(:descriptive_name, :new_app_descriptive_name, panels: {}, schedule: {})
  end

  def last_request_params
    @activity_params = {}
    @activity_params[:payload] = JSON.parse(request.body.read)["payload"]
    @activity_params
  end

  def cached_activity_for(app_ids, app_id_names_map, date_cutoff, cache_cutoff)
    cached_activity_stats = {}
    uncached_app_ids = []
    app_ids.each do |app_id|
      cache_key = "app_activity_stats/#{app_id}/#{date_cutoff}"
      cached_data = Rails.cache.read(cache_key)
      if cached_data
        cached_activity_stats[app_id] = cached_data
      else
        uncached_app_ids << app_id
      end
    end

    if uncached_app_ids.any?
      past_activity_groups = get_activity_for_cache(uncached_app_ids, date_cutoff, cache_cutoff)
      include_cutoff = (cache_cutoff - 1.day)
      past_activity_stats = format_activity(past_activity_groups, app_id_names_map, date_cutoff, include_cutoff)

      past_activity_stats.each do |app_id, formatted_stats|
        cache_key = "app_activity_stats/#{app_id}/#{date_cutoff}"
        expires_in = (Time.now.end_of_day - Time.now).seconds
        Rails.cache.write(cache_key, formatted_stats, expires_in:)
        cached_activity_stats[app_id] = formatted_stats
      end
    end

    cached_activity_stats
  end

  def uncached_activity_for(app_ids, app_id_names_map, cache_cutoff)
    app_activity_groups = get_activity_for(app_ids, cache_cutoff)
    format_activity(app_activity_groups, app_id_names_map, cache_cutoff, Time.now)
  end

  def get_activity_for_cache(app_ids, date_cutoff, cache_cutoff)
    ActivityEntry.requests
      .where(app_id: app_ids, created_at: date_cutoff..cache_cutoff)
      .group(:app_id, "created_at::date", :status)
      .count
  end

  def get_activity_for(app_ids, date_cutoff)
    ActivityEntry.requests
      .where(app_id: app_ids, created_at: date_cutoff..)
      .group(:app_id, "created_at::date", :status)
      .count
  end

  def format_activity(activity, app_id_names_map, date_cutoff, include_cutoff)
    included_dates_hash = (date_cutoff.to_date..include_cutoff.to_date).map do |date|
      [date, { date:, count: {} }]
    end.to_h

    results = {}
    activity.each do |(app_id, date, status), value|
      results[app_id] ||= { app_id: app_id_names_map[app_id], stats: included_dates_hash }
      results[app_id][:stats][date][:count][status] = value
    end
    results.each do |_, inner_hash|
      inner_hash[:stats] = inner_hash[:stats].values
    end
    results
  end

  def merge_activity_stats(cached_stats, todays_stats)
    cached_stats.each do |app_id, formatted_stats|
      formatted_stats[:stats] += todays_stats[app_id][:stats]
    end
    cached_stats.values
  end
end
