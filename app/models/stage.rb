# frozen_string_literal: true

class Stage < ActiveRecord::Base
  belongs_to :flow
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many  :connections,   foreign_key: "from_id", dependent: :destroy
  has_one   :connection,    foreign_key: "to_id",   dependent: :destroy
  has_and_belongs_to_many :users

  validates :owner, presence: true
  validates :flow,  presence: true
  validates :name,  presence: true, length: { minimum: 3 }
  validates :subcomponents, presence: true
end
