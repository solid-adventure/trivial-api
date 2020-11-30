# frozen_string_literal: true

class Team < ActiveRecord::Base
  before_destroy :change_teams
  has_many :users

  validates :name, presence: true, length: { minimum: 3 }, uniqueness: true

  def change_teams
    User.transaction do
      self.users.each do |team_user|
        team_user.team = Team.where(name: 'individual').first
        team_user.save!
      end
    end
  end
end
