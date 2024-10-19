class Organization < ApplicationRecord
  audited
  has_associated_audits

  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  has_many :owned_registers, class_name: 'Register', as: :owner
  has_many :owned_register_items, class_name: 'RegisterItem', as: :owner
  has_many :owned_dashboards, class_name: 'Dashboard', as: :owner, inverse_of: :owner

  has_many :org_roles, dependent: :destroy
  has_many :users, through: :org_roles

  validates :billing_email, presence: true
  validates :name, presence: true

  after_create :create_default_dashboard
  after_create :create_default_register

  default_scope { order(created_at: :asc) }

  def admin?(user)
    org_roles.find_by(user: user)&.role == 'admin'
  end

def own_and_associated_audits
    Audited::Audit.where(<<-SQL,
      (auditable_type = ? AND auditable_id = ?) OR
      (associated_type = ? AND associated_id = ?) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?)) OR
      (auditable_type = ? AND auditable_id IN (?))
    SQL
      'Organization', id,
      'Organization', id,
      'App', owned_apps.pluck(:id),
      'Manifest', owned_manifests.pluck(:id),
      'ManifestDraft', owned_manifest_drafts.pluck(:id),
      'CredentialSet', owned_credential_sets.pluck(:id),
      'Register', owned_registers.pluck(:id),
      'Dashboard', owned_dashboards.pluck(:id),
      'User', users.pluck(:id)
    )
  end

  private
    def create_default_register
      Register.create!(
          name: 'Sales',
          owner: self,
          meta: {}
      )
    end

    def create_default_dashboard
      Dashboard.create!(
          name: "Default Dashboard",
          owner: self
      )
    end
end
