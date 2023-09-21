class ManifestDraftsController < ApplicationController

  def show
    render json: manifest_draft
  end

  def create
    @manifest_draft = ManifestDraft.create_for_manifest!(manifest, manifest_draft_params)
    @permission = Permission.new(user: current_user, permissable: @manifest_draft)
    @permission.permits!(:all)
    @permission.save!
    render json: @manifest_draft
  end

  def update
    manifest_draft.update_attributes!(manifest_draft_params)
    render json: manifest_draft
  end

  def credentials
    render json: {credentials: manifest_draft.credentials}
  end

  def update_credentials
    manifest_draft.save_credentials! params[:credentials]
    render json: {ok: true}
  end

  private

  def manifest
    @manifest ||= current_user.manifests.find(params[:manifest_id])
  end

  def manifest_draft
    @manifest_draft ||= current_user.manifest_drafts.unexpired.find_by_token!(params[:id])
  end

  def manifest_draft_params
    draft = original_body['manifest_draft'] || {}
    {
      action: draft['action'],
      content: draft['content']
    }
  end

  # Returns the parsed JSON body without alteration
  def original_body
    @original_body ||= ActiveSupport::JSON::decode(request.raw_post)
  end

end
