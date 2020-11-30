# frozen_string_literal: true

class User < ActiveRecord::Base
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable
  include DeviseTokenAuth::Concerns::User

  belongs_to :team
  has_many   :board,    foreign_key: "owner_id",   dependent: :destroy
  has_many   :flow,    foreign_key: "owner_id",   dependent: :destroy
  has_many   :stage,    foreign_key: "owner_id",   dependent: :destroy
  has_and_belongs_to_many :boards
  has_and_belongs_to_many :flows
  has_and_belongs_to_many :stages

  enum role: [:member, :team_manager, :admin]
  enum approval: [:pending, :approved, :rejected]

  validates :name,    presence: true, length: { minimum: 3 }
  validates :team,    presence: true
end
