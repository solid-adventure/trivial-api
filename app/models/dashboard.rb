class Dashboard < ApplicationRecord
  include Ownable
  include Permissible

  audited
  has_associated_audits

  validates :owner,
    presence: true
  validates :owner_type,
    inclusion: {
      in: %w[Organization],
      message: "Only Organization owned Dashboards are currently supported"
    }
  validates :name,
    presence: true,
    uniqueness: {
      scope: %i[owner],
      message: "%{value} already exists as a dashboard name for this organization"
    }
  validates :dashboard_type,
    presence: true

  belongs_to :owner, polymorphic: true, inverse_of: :owned_dashboards
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user, inverse_of: :permitted_dashboards

  has_many :charts, inverse_of: :dashboard
end
