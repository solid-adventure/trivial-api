class ManifestDraftsController < ApplicationController

  def show
    render json: manifest_draft
  end

  def create
    @manifest_draft = ManifestDraft.create_for_manifest!(manifest, manifest_draft_params)
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
    # This should be as easy as:
    #
    #   params.require(:manifest_draft).permit(:action, content: {})
    #
    # However, in that approach, strong parameters strips nested
    # arrays from the 'content' parameter. That effectively removes
    # all of the transformation steps from the manifest, so the
    # following permits the entire manifest without altering it.
    draft = params.require(:manifest_draft)
    {
      action: draft[:action],
      content: ActiveSupport::JSON::decode(draft[:content].to_json)
    }
  end

end
