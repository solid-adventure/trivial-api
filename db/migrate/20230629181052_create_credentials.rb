class CreateCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :credentials do |t|
      t.string :name
      t.string :owner_type
      t.json :secret_value

      t.timestamps
    end
  end
end
