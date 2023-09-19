class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions, id: false do |t|
      t.references :user, foreign_key: true
      t.references :permissable, polymorphic: true

      t.integer :permit_mask, default: 0

      t.timestamps
    end
  end
end
