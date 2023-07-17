class MigrateUserIdToOwnerId < ActiveRecord::Migration[7.0]
  class TempCredentialSet < ActiveRecord::Base
    self.table_name = 'credential_sets'
  end

  def up
    TempCredentialSet.find_each do |credential_set|
      credential_set.update_columns(owner_id: credential_set.user_id, owner_type: 'User')
    end
  end

  def down
    TempCredentialSet.find_each do |credential_set|
      credential_set.update_columns(owner_id: nil, owner_type: nil)
    end
  end
end
