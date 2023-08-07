class CreatePermissionReferences < ActiveRecord::Migration[7.0]
  def change
    add_reference :permissions, :owner, polymorphic: true, index: true
    add_reference :permissions, :resource, polymorphic: true, index: true
  end
end
