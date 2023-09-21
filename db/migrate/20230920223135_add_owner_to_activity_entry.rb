class AddOwnerToActivityEntry < ActiveRecord::Migration[7.0]
  def change
    add_reference :activity_entries, :owner, polymorphic: true, index: true
  end
end
