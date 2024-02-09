class Organization < ApplicationRecord
  audited

  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  has_many :owned_registers, class_name: 'Register', as: :owner
  has_many :owned_register_items, class_name: 'RegisterItem', as: :owner
  
  has_many :org_roles, dependent: :delete_all
  has_many :users, through: :org_roles

  validates :billing_email, presence: true
  validates :name, presence: true
end
