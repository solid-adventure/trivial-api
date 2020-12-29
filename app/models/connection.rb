# frozen_string_literal: true

class Connection < ActiveRecord::Base
  belongs_to :flow
  belongs_to :from, class_name: 'Stage', foreign_key: :from_id
  belongs_to :to,   class_name: 'Stage', foreign_key: :to_id

  validate  :two_stages_cannot_be_the_same
  validates :flow,      presence: true
  validates :from,      presence: true
  validates :to,        presence: true
  validates :transform, presence: true
  validate  :two_stages_must_be_on_the_same_flow

  private

  def two_stages_must_be_on_the_same_flow
    if Stage.find_by_id(self.from_id) && Stage.find_by_id(self.from_id).flow != Flow.find_by_id(self.flow_id) ||
       Stage.find_by_id(self.to_id) && Stage.find_by_id(self.to_id).flow != Flow.find_by_id(self.flow_id)
      errors.add(:flow, 'stages must be on the same flow!')
    end
  end

  def two_stages_cannot_be_the_same
    if self.from_id == self.to_id
      errors.add(:from, 'two stages cannot be the same!')
    end
  end

  def team_manager_cannot_be_pending
    if team_manager? && pending?
      errors.add(:approval, 'cannot be pending for team manager')
    end
  end
end
