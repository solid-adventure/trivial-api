# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :customers
  has_many :manifests
  has_many :webhooks
  has_many :apps
  has_many :activity_entries
  has_many :manifest_drafts
  has_many :credential_sets, as: :owner

  enum role: %i[member admin]
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

  def all_credential_sets
    user_credentials = credential_sets.order(:id)
    customers_credentials = customers.map { |customer| customer.credential_sets }.flatten
    customers_credentials + user_credentials
  end

  # Find a CredentialSet by external id
  def find_credential_by_external_id(external_id)
    credential_sets.or(CredentialSet.where(owner_type: 'customer', owner_id: user.customers.pluck(:id)))
                   .find_by(external_id: external_id)
  end

  private

  def set_values_for_individual
    if !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end

end
