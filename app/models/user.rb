# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :customers
  has_many :org_roles, :dependent => :destroy
  has_many :organizations, through: :org_roles
  
  ASSOCIATED_RESOURCES = ['apps', 'credential_sets', 'manifests', 'manifest_drafts']
  # to be deprecated associations upon ownership transfer
  has_many :apps
  has_many :manifests
  has_many :manifest_drafts
  has_many :activity_entries
  has_many :credential_sets
  
  # new ownership associations
  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  
  # new permission based associations
  has_many :permissions
  has_many :permitted_apps, -> { distinct }, through: :permissions, source: :permissible, source_type: 'App'
  has_many :permitted_manifests, -> { distinct }, through: :permissions, source: :permissible, source_type: 'Manifest'
  has_many :permitted_manifest_drafts, -> { distinct }, through: :permissions, source: :permissible, source_type: 'ManifestDraft'
  has_many :permitted_credential_sets, -> { distinct }, through: :permissions, source: :permissible, source_type: 'CredentialSet'

  enum role: %i[member admin client]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }

  before_save :set_values_for_individual
  before_create :set_trial_expires_at

  def ensure_aws_role!
    name = "#{ENV['AWS_ROLE_PREFIX'] || ''}lambda-ex-#{id.to_s(36)}"
    update!(aws_role: Role.create!(name: name).arn) if aws_role.blank?
    aws_role
  end

  def active_for_authentication?
    ensure_aws_role!
    super
  end

  def set_trial_expires_at
    self.trial_expires_at = Time.now + 14.day
  end

  def associated_apps
    associated_resources('apps')
  end

  def associated_activity_entries
    associated_resources_via_app('activity_entries')
  end
  
  # Only explicitly shared credential sets are exposed and are  not visibile via org membership alone
  def associated_credential_sets
    associated_resources('credential_sets', 'admin')
  end

  def associated_manifests
    associated_resources_via_app('manifests')
  end

  def associated_manifest_drafts
    associated_resources_via_app('manifest_drafts')
  end


  private

  def associated_resources(resource_type, roles=['admin', 'member'])
    model_class = resource_type.classify.constantize

    orgs = self.organizations.where(org_roles: { role: roles })
    membership_associated = model_class.where(owner: [self] + orgs)
    permitted = model_class.where(id: self.send("permitted_#{resource_type}").pluck(:id))

    membership_associated.or(permitted)
  end

  def associated_resources_via_app(resource_type, roles=['admin', 'member'])
    model_class = resource_type.classify.constantize

    orgs = self.organizations.where(org_roles: { role: roles })
    membership_associated = model_class.where(app: App.where(owner: [self] + orgs))
    permitted = model_class.where(app: App.where(id: self.permitted_apps.pluck(:id)))

    membership_associated.or(permitted)
  end

  def set_values_for_individual
    if !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end
end
