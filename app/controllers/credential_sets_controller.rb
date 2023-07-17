class CredentialSetsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:patch, :update_api_key, :show_app]
  before_action :authenticate_app!, only: [:patch, :show_app]

  def index
    render json: {credential_sets: current_user.all_credential_sets.map(&:api_attrs)}
  end

  def create
    @credential_set = current_user.credential_sets.new(credential_set_params)
    @credential_set.owner = current_user
    @credential_set.save!
    if params.has_key?(:credentials)
      @credential_set.credentials.secret_value = params[:credentials]
      @credential_set.credentials.save!
    end
    render json: {credential_set: @credential_set.api_attrs}
  end

  def show
    render json: {
      credential_set: credential_set.api_attrs,
      credentials: credential_set.credentials.secret_value
    }
  end

  def show_app
    render json: {
      credential_set: credential_set_app.api_attrs,
      credentials: credential_set_app.credentials.secret_value
    }
  end

  def update
    if params.has_key?(:credential_set)
      credential_set.update!(credential_set_params)
    end
    if params.has_key?(:credentials)
      credential_set.credentials.secret_value = params[:credentials]
      credential_set.credentials.save!
    end
    render json: {credential_set: credential_set.api_attrs}
  end

  def patch
    patchable_credential_set.credentials.patch_path!(
      params[:path],
      params[:credentials][:current_value],
      params[:credentials][:new_value]
    )
    render json: {ok: true}
  rescue Credentials::InvalidPatch => e
    logger.error "Failed to patch credential set credentials #{e}"
    render status: 422, json: {ok: false, error: e.message}
  end

  def destroy
    credential_set.credentials.destroy!
    credential_set.destroy!
    render status: :ok
  end

  def update_api_key
    @keys = ApiKeys.for_key!(auth_key)
    @credential_set = @keys.app.user.find_credential_by_external_id(params[:id])
    render json: {
      api_key: @keys.refresh_in_credential_set!(@credential_set, auth_key, params[:path])
    }
  rescue ApiKeys::OutdatedKeyError
    render status: :conflict
  rescue => e
    logger.error "API key refresh failed - #{e}: #{e.backtrace.join("\n")}"
    render status: :unauthorized
  end

  private

  def credential_set
    @credential_set ||= current_user.find_credential_by_external_id(params[:id])
  end

  def credential_set_app
    @credential_set_app ||= current_app.user.find_credential_by_external_id(params[:id])
  end

  def patchable_credential_set
    @credential_set ||= current_app.user.find_credential_by_external_id(params[:id])
  end

  def credential_set_params
    params.require(:credential_set).permit(:name, :credential_type)
  end

end
