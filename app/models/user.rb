# frozen_string_literal: true
require 'env_handler'

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User
  include EnvHandler

  audited redacted: filtered_attributes
  has_owned_audits

  has_and_belongs_to_many :customers
  has_many :org_roles, :dependent => :destroy
  has_many :organizations, through: :org_roles

  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  has_many :owned_registers, class_name: 'Register', as: :owner
  has_many :owned_register_items, class_name: 'RegisterItem', as: :owner
  has_many :owned_dashboards, class_name: 'Dashboard', as: :owner

  has_many :permissions
  has_many :permitted_apps, -> { distinct }, through: :permissions, source: :permissible, source_type: 'App'
  has_many :permitted_manifests, -> { distinct }, through: :permissions, source: :permissible, source_type: 'Manifest'
  has_many :permitted_manifest_drafts, -> { distinct }, through: :permissions, source: :permissible, source_type: 'ManifestDraft'
  has_many :permitted_credential_sets, -> { distinct }, through: :permissions, source: :permissible, source_type: 'CredentialSet'
  has_many :permitted_registers, -> { distinct }, through: :permissions, source: :permissible, source_type: 'Register'
  has_many :permitted_register_items, -> { distinct }, through: :permissions, source: :permissible, source_type: 'RegisterItem'
  has_many :permitted_dashboards, -> { distinct }, through: :permissions, source: :permissible, source_type: 'Dashboard'

  enum role: %i[member admin client]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }

  before_save :set_values_for_individual
  before_create :set_trial_expires_at

  alias_attribute :reference_name, :name

  def ensure_aws_role!
    begin
      aws_env_set?
      name = "#{ENV['AWS_ROLE_PREFIX'] || ''}lambda-ex-#{id.to_s(36)}"
      update!(aws_role: Role.create!(name: name).arn) if aws_role.blank?
      aws_role
    rescue EnvHandler::MissingEnvVariableError
      return ""
    end
  end

  def active_for_authentication?
    ensure_aws_role!
    super
  end

  def set_trial_expires_at
    self.trial_expires_at = Time.now + 14.day
  end

  def accept_role!
    if invitation_metadata
      if role = OrgRole.find_by(organization_id: invitation_metadata["org_id"], user: self)
        role.update_column(:role, invitation_metadata["role"]) unless role.role == invitation_metadata["role"]
      else
        OrgRole.create(
          organization_id: invitation_metadata["org_id"],
          user: self,
          role: invitation_metadata["role"]
        )
      end

      self.update_column(:invitation_metadata, nil)
    else 
      raise ActiveRecord::RecordNotFound
    end
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

  def associated_organizations
    return Organization.all if self.role == 'client'
    return self.organizations
  end

  def associated_registers
    associated_resources('registers')
  end

  def associated_register_items
    associated_resources('register_items')
  end

  def associated_dashboards
    associated_resources('dashboards')
  end

  private

  def associated_resources(resource_type, org_roles=['admin', 'member'])
    model_class = resource_type.classify.constantize

    return model_class.all if self.role == 'client'

    orgs = self.organizations.where(org_roles: { role: org_roles })
    membership_associated = model_class.where(owner: [self] + orgs)
    permitted = model_class.where(id: self.send("permitted_#{resource_type}").pluck(:id))

    membership_associated.or(permitted)
  end

  def associated_resources_via_app(resource_type, org_roles=['admin', 'member'])
    model_class = resource_type.classify.constantize

    return model_class.all if self.role == 'client'

    orgs = self.organizations.where(org_roles: { role: org_roles })
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
