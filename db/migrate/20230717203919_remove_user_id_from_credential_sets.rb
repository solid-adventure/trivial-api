class RemoveUserIdFromCredentialSets < ActiveRecord::Migration[7.0]
  def change
    remove_column :credential_sets, :user_id, :integer
  end
end
