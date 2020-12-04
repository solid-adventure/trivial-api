# frozen_string_literal: true

class Flow < ActiveRecord::Base
  belongs_to :board
  has_many  :stages, dependent: :destroy
  has_many  :connections, dependent: :destroy

  validates :board, presence: true
  validates :name,  presence: true, length: { minimum: 3 }
end
