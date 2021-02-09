# frozen_string_literal: true

class Stage < ActiveRecord::Base
  belongs_to :flow

  validates :flow,  presence: true
  # validates :name,  presence: true, length: { minimum: 3 }
  # validates :subcomponents, presence: true
end
