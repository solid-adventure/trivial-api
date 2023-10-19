class Permission < ApplicationRecord
  include PermissionConstants

  belongs_to :user
  belongs_to :permissible, polymorphic: true

  validates :user, presence: true
  validates :permissible, presence: true
  validates :permit, presence: true
end
