class AddOwnerToCredentialSets < ActiveRecord::Migration[7.0]
  def change
    add_reference :credential_sets, :owner, polymorphic: true, index: true
  end
end
