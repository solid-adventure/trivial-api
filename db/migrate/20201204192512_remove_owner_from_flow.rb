class RemoveOwnerFromFlow < ActiveRecord::Migration[6.0]
  def change
    remove_column :flows, :owner_id
  end
end
