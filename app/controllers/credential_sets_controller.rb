class CredentialSetsController < ApplicationController

  def index
    render json: {credential_sets: current_user.credential_sets.order(:id)}
  end

end
