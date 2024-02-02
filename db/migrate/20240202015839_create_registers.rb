class CreateRegisters < ActiveRecord::Migration[7.0]
  def change
    create_table :registers do |t|
      t.string :name
      t.string :type
      t.string :units
      t.integer :multiplier
      t.jsonb :meta
      t.string :owner_type
      t.integer :owner_id
      t.timestamps
    end
  end
end
