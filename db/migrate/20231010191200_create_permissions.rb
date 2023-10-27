class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions do |t|
      t.references :user, foreign_key: true
      t.references :permissible, polymorphic: true

      t.integer :permit, default: 0

      t.timestamps
    end
  end
end
