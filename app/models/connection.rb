# frozen_string_literal: true

class Connection < ActiveRecord::Base
  belongs_to :flow

  validates :flow,      presence: true
  validates :from,      presence: true
  validates :to,        presence: true
  validates :transform, presence: true
end
