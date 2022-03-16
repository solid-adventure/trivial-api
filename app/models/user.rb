# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  has_many :manifests
  has_many :webhooks
  has_many :apps
  has_many :activity_entries
  has_many :manifest_drafts
  has_many :credential_sets

  enum role: %i[member admin]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }

  before_save :set_values_for_individual

  def ensure_aws_role!
    name = "#{ENV['AWS_ROLE_PREFIX'] || ''}lambda-ex-#{id.to_s(36)}"
    update!(aws_role: Role.create!(name: name).arn) if aws_role.blank?
    aws_role
  end

  def active_for_authentication?
    ensure_aws_role!
    super
  end

  private

  def set_values_for_individual
    if !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end


end
