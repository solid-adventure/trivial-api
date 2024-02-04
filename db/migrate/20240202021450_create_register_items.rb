class CreateRegisterItems < ActiveRecord::Migration[7.0]
  def change
    create_table :register_items do |t|
      t.references :register, null: false, foreign_key: true
      t.string :description
      t.decimal :amount
      t.string :units
      t.string :owner_type
      t.integer :owner_id
      t.string :unique_key
      t.string :meta0
      t.string :meta1
      t.string :meta2
      t.string :meta3
      t.string :meta4
      t.string :meta5
      t.string :meta6
      t.string :meta7
      t.string :meta8
      t.string :meta9
      t.timestamps

    end

    add_index(:register_items, [:unique_key, :register_id], unique: true)
    add_index(:register_items, [:owner_type, :owner_id])

  end
end
