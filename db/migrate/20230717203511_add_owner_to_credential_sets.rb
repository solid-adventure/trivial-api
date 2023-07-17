class AddOwnerToCredentialSets < ActiveRecord::Migration[7.0]
  def change
    add_column :credential_sets, :owner_id, :bigint
    add_column :credential_sets, :owner_type, :string
    add_reference :credential_sets, :owner, polymorphic: true, index: true
  end
end
