class AppsController < ApplicationController

  def index
    render json: apps.as_json(methods: [:aws_role]).to_json
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
    @app.save!
    render json: @app.as_json(methods: [:aws_role])
  end

  def show
    authorize! :read, app
    render json: app.as_json(methods: [:aws_role])
  end

  def update
    authorize! :update, app
    app.update!(app_params)
    render json: app
  end

  def copy
    authorize! :update, app
    app_copy = app.copy!(nil, params[:new_app_descriptive_name])
    render json: app_copy
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
    if params[:include_deleted].present?
      @apps.order(:descriptive_name)
    else
      @apps.kept.order(:descriptive_name)
    end
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
