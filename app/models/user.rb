# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :customers
  has_many :webhooks
  has_many :apps
  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :manifests
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :manifest_drafts
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :activity_entries
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :credential_sets
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  has_many :org_roles, :dependent => :destroy
  has_many :organizations, through: :org_roles

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

  private

  def set_values_for_individual
    if !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end

end
