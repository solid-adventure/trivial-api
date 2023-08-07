class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions do |t|
      t.string :name
      t.text :description
      t.bigint :resource_id
      t.string :resource_type
      t.string :access
      t.bigint :owner_id
      t.string :owner_type

      t.timestamps
    end
  end
end
