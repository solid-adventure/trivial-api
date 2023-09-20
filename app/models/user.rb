# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :customers
  has_many :manifests, through: :permissions
  has_many :webhooks
  has_many :activity_entries, through: :permissions
  has_many :manifest_drafts, through: :permissions
  has_many :credential_sets
  has_many :org_roles
  has_many :organizations, through: :org_roles
  has_many :permissions
  has_many :apps, through: :permissions

  accepts_nested_attributes_for :org_roles
  accepts_nested_attributes_for :permissions
  
  enum role: %i[member admin client]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }

  before_save :set_values_for_individual
  before_create :set_trial_expires_at

  def get_role_for(org)
    if org = orgs.find_by(name: org)
      org_roles.find(org.id).role
    else
      nil
    end
  end

  def update_role_for(org, role)
    if org = orgs.find_by(name: org)
      org_roles.find(org.id).update_column(:role, role)
    else 
      nil
    end
  end

  def set_role_for(org, role)
    if org = Org.find_by(name: org)
      org_roles.create(org_id: org.id, user_id: id, role: role)
    else
      nil
    end
  end
  
  def get_app_permit_for(app)
    if app = apps.find_by(name: app)
      permissions.find(app.id).permits
    else
      nil
    end
  end

  def update_app_permit_for(app, *args)
    byebug
    if app = apps.find_by(name: app)
      permissions.find(app_id).permits!(%i[args])
    else 
      nil
    end
  end

  def set_app_permit_for(app, *args)
    byebug
    if app = App.find_by(name: app)
      new_permit = permissions.create(user_id: id, app_id: app.id)
      new_permit.permits!(%i[args])
    else
      nil
    end
  end
  
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
