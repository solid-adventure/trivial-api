class AddOwnerToModels < ActiveRecord::Migration[7.0]
  def change
    add_reference :apps, :owner, polymorphic: true, index: true
    add_reference :manifests, :owner, polymorphic: true, index: true
    add_reference :manifest_drafts, :owner, polymorphic: true, index: true
    #add_reference :activity_entries, :owner, polymorphic: true, index: true
    #add_reference :credential_sets, :owner, polymorphic: true, index: true
  end
end
