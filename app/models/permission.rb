class Permission < ApplicationRecord
  belongs_to :user
  belongs_to :permissable, polymorphic: true

  # Defined permissions and their bit alignment
  READ_BIT = 0b1
  UPDATE_BIT = 0b10
  DELETE_BIT = 0b100
  TRANSFER_BIT = 0b1000
  GRANT_BIT = 0b10000
  REVOKE_BIT = 0b100000

  # Defined permissions hash
  PERMISSIONS_HASH = { 
    read: READ_BIT,
    update: UPDATE_BIT,
    destroy: DELETE_BIT,
    transfer: TRANSFER_BIT,
    grant: GRANT_BIT,
    revoke: REVOKE_BIT,
  }
end
