# frozen_string_literal: true

class Team < ActiveRecord::Base
  has_many :users
  validates :name, presence: true, length: { minimum: 3 }, uniqueness: true

  after_destroy :reset_team_members

  def reset_team_members
    users.update_all(team_id: nil, role: 'member', approval: 'approved')
  end
end
