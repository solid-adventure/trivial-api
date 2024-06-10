class AddRegisterItemToActivityEntries < ActiveRecord::Migration[7.0]
  def change
    add_reference :activity_entries, :register_item, foreign_key: true
  end
end
