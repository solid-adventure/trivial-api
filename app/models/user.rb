# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :recoverable
  include DeviseTokenAuth::Concerns::User

  attr_accessor :current_password
  belongs_to :team, optional: true
  has_many   :board, foreign_key: 'owner_id', dependent: :destroy
  has_and_belongs_to_many :boards
  has_many :manifests
  has_many :webhooks
  has_many :apps

  enum role: %i[member team_manager admin]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }
  validate  :team_manager_cannot_be_pending
  validate  :belongs_to_valid_team

  before_save :set_values_for_individual
  after_save :set_teammates_as_member

  private

  def team_manager_cannot_be_pending
    if team_manager? && pending?
      errors.add(:approval, 'cannot be pending for team manager')
    end
  end

  def set_values_for_individual
    if team.nil? && !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end

  def set_teammates_as_member
    if saved_changes[:role].present? && team_manager?
      team.users.team_manager.where.not(id: id).update_all(role: "member")
    end
  end

  def belongs_to_valid_team
    errors.add(:team_id, "is not valid!") if team.nil? && team_id.present?
  end
end
