# frozen_string_literal: true

class Connection < ActiveRecord::Base
  belongs_to :flow
  belongs_to :from, class_name: 'Stage', foreign_key: :from_id
  belongs_to :to,   class_name: 'Stage', foreign_key: :to_id

  validates :flow,  presence: true
  validates :from,  presence: true
  validates :to,    presence: true
end
