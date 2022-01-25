class CredentialSetsController < ApplicationController

  def index
    render json: {credential_sets: current_user.credential_sets.order(:id)}
  end

  def create
    @credential_set = current_user.credential_sets.create! credential_set_params
    if params.has_key?(:credentials)
      @credential_set.credentials.secret_value = params[:credentials]
      @credential_set.credentials.save!
    end
    render json: {credential_set: @credential_set}
  end

  def show
    render json: {credentials: credential_set.credentials.secret_value}
  end

  def update
    if params.has_key?(:credential_set)
      credential_set.update!(credential_set_params)
    end
    if params.has_key?(:credentials)
      credential_set.credentials.secret_value = params[:credentials]
      credential_set.credentials.save!
    end
    render json: {credential_set: credential_set}
  end

  private

  def credential_set
    @credential_set ||= current_user.credential_sets.find(params[:id])
  end

  def credential_set_params
    params.require(:credential_set).permit(:name, :credential_type)
  end

end
