class AppsController < ApplicationController

  def index
    render json: apps.as_json(methods: [:aws_role]).to_json
  end

  def create
    @app = App.new(app_params)
    @app.user = current_user
    @app.save!
    render json: @app.as_json(methods: [:aws_role])
  end

  def show
    render json: app.as_json(methods: [:aws_role])
  end

  def update
    app.update!(app_params)
    render json: app
  end

  def copy
    app_copy = app.copy!(nil, params[:new_app_descriptive_name])
    render json: app_copy
  end

  def destroy
    app.discard!
    head :ok
  end

  def name_suggestion
    render json: {suggestion: App.new.name_suggestion}
  end
  private

  def app
    App.kept.accessible_by(Ability.new(current_user)).find_by_name(params[:id])
  end

  def apps
    if params[:include_deleted].present?
      App.accessible_by(Ability.new(current_user)).order(:descriptive_name)
    else
      App.kept.accessible_by(Ability.new(current_user)).order(:descriptive_name)
    end
  end

  def app_params
      params.permit(:descriptive_name, :new_app_descriptive_name, panels: {}, schedule: {})
  end
end
