class OrgRole < ApplicationRecord
  ROLES = %w(admin member guest).freeze

  audited

  validates :user_id, presence: true
  validates :organization_id, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  belongs_to :organization
  belongs_to :user
end
