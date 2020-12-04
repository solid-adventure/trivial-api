class RemoveOwnerFromStage < ActiveRecord::Migration[6.0]
  def change
    remove_column :stages, :owner_id
  end
end
