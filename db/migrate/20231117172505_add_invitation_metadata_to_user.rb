class AddInvitationMetadataToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :invitation_metadata, :string
  end
end
