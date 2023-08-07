class AddOwnerIdAndOwnerTypeToApp < ActiveRecord::Migration[7.0]
  def change
    add_column :apps, :owner_id, :bigint
    add_column :apps, :owner_type, :string
    add_reference :apps, :owner, polymorphic: true, index: true
  end
end
