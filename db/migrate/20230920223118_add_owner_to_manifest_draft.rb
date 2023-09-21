class AddOwnerToManifestDraft < ActiveRecord::Migration[7.0]
  def change
    add_reference :manifest_drafts, :owner, polymorphic: true, index: true
  end
end
