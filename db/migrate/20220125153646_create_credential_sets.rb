class CreateCredentialSets < ActiveRecord::Migration[6.0]
  def change
    create_table :credential_sets do |t|
      t.uuid :external_id, null: false, index: { unique: true }
      t.belongs_to :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :credential_type, null: false
      t.timestamps
    end
  end
end
