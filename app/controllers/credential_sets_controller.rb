class CredentialSetsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:patch]

  def index
    render json: {credential_sets: current_user.credential_sets.order(:id).map(&:api_attrs)}
  end

  def create
    @credential_set = current_user.credential_sets.create! credential_set_params
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
    CredentialSet.find_by_external_id!(params[:id]).credentials.patch_path!(
      params[:path],
      params[:credentials][:current_value],
      params[:credentials][:new_value]
    )
    render json: {ok: true}
  rescue CredentialsBase::InvalidPatch => e
    logger.error "Failed to patch credential set credentials #{e}"
    render status: 422, json: {ok: false, error: e.message}
  end

  def destroy
    credential_set.credentials.destroy!
    credential_set.destroy!
    render status: :ok
  end

  private

  def credential_set
    @credential_set ||= current_user.credential_sets.find_by_external_id!(params[:id])
  end

  def credential_set_params
    params.require(:credential_set).permit(:name, :credential_type)
  end

end
