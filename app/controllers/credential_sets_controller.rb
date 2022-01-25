class CredentialSetsController < ApplicationController

  def index
    render json: {credential_sets: current_user.credential_sets.order(:id)}
  end

  def create
    @credential_set = current_user.credential_sets.create! credential_set_params
    render json: {credential_set: @credential_set}
  end

  private

  def credential_set_params
    params.require(:credential_set).permit(:name, :credential_type)
  end

end
