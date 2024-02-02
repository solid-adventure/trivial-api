class CreateRegisterItems < ActiveRecord::Migration[7.0]
  def change
    create_table :register_items do |t|
      t.references :register, null: false, foreign_key: true
      t.string :description
      t.integer :amount
      t.decimal :multiplier
      t.string :units
      t.string :owner_type
      t.integer :owner_id
      t.jsonb :meta
      t.string :uniqueness_key
      t.timestamps
    end

    add_index(:register_items, [:uniqueness_key, :register_id], unique: true)

  end
end
