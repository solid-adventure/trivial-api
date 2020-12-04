# frozen_string_literal: true

class Stage < ActiveRecord::Base
  belongs_to :flow
  has_many  :connections,   foreign_key: 'from_id', dependent: :destroy
  has_one   :connection,    foreign_key: 'to_id',   dependent: :destroy

  validates :flow,  presence: true
  validates :name,  presence: true, length: { minimum: 3 }
  validates :subcomponents, presence: true
end
