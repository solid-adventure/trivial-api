class RemoveUserFromModels < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :apps, :users
    remove_index :apps, :user_id
    remove_column :apps, :user_id, :integer

    remove_column :manifests, :user_id, :integer
    
    remove_foreign_key :manifest_drafts, :users
    remove_index :manifest_drafts, :user_id
    remove_column :manifest_drafts, :user_id, :integer
    
    remove_foreign_key :activity_entries, :users
    remove_index :activity_entries, :user_id
    remove_column :activity_entries, :user_id, :integer
    
    remove_foreign_key :credential_sets, :users
    remove_index :credential_sets, :user_id
    remove_column :credential_sets, :user_id, :integer
  end
end
