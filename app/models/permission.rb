class Permission < ApplicationRecord
  belongs_to :user
  belongs_to :permissable, polymorphic: true

  # Defined permissions and their bit alignment
  READ_BIT = 1
  UPDATE_BIT = 2
  DELETE_BIT = 4
  TRANSFER_BIT = 8
  GRANT_BIT = 16
  REVOKE_BIT = 32

  # Defined permissions hash
  PERMITS = { 
    read: READ_BIT,
    update: UPDATE_BIT,
    destroy: DELETE_BIT,
    transfer: TRANSFER_BIT,
    grant: GRANT_BIT,
    revoke: REVOKE_BIT,
  }

  def permits!(*permissions)
    if permissions.include?(:all)
      permissions_mask = PERMITS.values.reduce(0, :|)
    else
      permissions_mask = permissions.reduce(0) do |mask, permission|
        mask | PERMITS[permission]
      end
    end
  end

  def permits
    PERMITS.keys.select do |permission|
      (permissions_mask & PERMITS[permission]).nonzero?
    end
  end

  def permits?(permission)
    (permissions_mask & PERMITS[permission]).nonzero?
  end
end
