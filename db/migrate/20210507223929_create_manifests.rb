class CreateManifests < ActiveRecord::Migration[6.0]
  def change
    create_table :manifests do |t|
      t.string :app_id
      t.json :content
      t.integer :owner_id

      t.timestamps
    end
  end
end
