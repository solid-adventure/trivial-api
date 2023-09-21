class AddOwnerToManifest < ActiveRecord::Migration[7.0]
  def change
    add_reference :manifests, :owner, polymorphic: true, index: true
  end
end
