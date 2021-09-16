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

  enum role: %i[member admin]
  enum approval: %i[pending approved rejected]

  validates :name, presence: true, length: { minimum: 3 }

  before_save :set_values_for_individual

  private

  def set_values_for_individual
    if !admin?
      self.role = 'member'
      self.approval = 'approved'
    end
  end


end
