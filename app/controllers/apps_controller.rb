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
    @app.user = current_user
    @app.owner = current_user
    @app.save!
    Permission.grant_all(permissible: @app, user_id: current_user.id)
    render json: @app.as_json(methods: [:aws_role])
  end

  def show
    authorize! :read, app
    render json: app.as_json(methods: [:aws_role])
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
  private

  def app
    @app ||= App.kept.find_by_name(params[:id])
  end

  def apps
    @apps ||= App.accessible_by(Ability.new(current_user))
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
end
