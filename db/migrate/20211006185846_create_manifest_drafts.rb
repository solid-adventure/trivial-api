class CreateManifestDrafts < ActiveRecord::Migration[6.0]
  def change
    create_table :manifest_drafts do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :app, null: false, foreign_key: true
      t.belongs_to :manifest, null: false, foreign_key: true
      t.jsonb :content
      t.string :action
      t.uuid :token, null: false, index: { unique: true }
      t.datetime :expires_at, precision: 6, null: false
      t.timestamps
    end
  end
end
