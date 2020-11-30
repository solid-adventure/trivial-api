class CreateConnections < ActiveRecord::Migration[6.0]
  def change
    create_table :connections do |t|
      t.references  :from,  foreign_key: { to_table: :stages }
      t.references  :to,    foreign_key: { to_table: :stages }
      t.references  :flow

      t.timestamps
    end
  end
end
