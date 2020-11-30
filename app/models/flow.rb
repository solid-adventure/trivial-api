# frozen_string_literal: true

class Flow < ActiveRecord::Base
  belongs_to :board
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many  :stages, dependent: :destroy
  has_many  :connections, dependent: :destroy
  has_and_belongs_to_many :users

  validates :board, presence: true
  validates :owner, presence: true
  validates :name,  presence: true, length: { minimum: 3 }
end
