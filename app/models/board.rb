# frozen_string_literal: true

class Board < ActiveRecord::Base
  has_many :flows, dependent: :destroy
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_and_belongs_to_many :users

  enum access_level: %i[free trivial team secret]

  validates :owner, presence: true
  validates :name,  presence: true, length: { minimum: 3 }
  validates :slug,  presence: true, length: { minimum: 5 }, uniqueness: true

  after_initialize :generate_slug
  after_create :check_flow

  scope :available, ->(user) {
    return Board.free if user.nil?
    return Board.all if user.admin?
    
    available = Board.free.or(Board.trivial)
    available = available.or(Board.where(access_level: 'team', owner_id: user.team.owner.id)) if user.approved? && user.team&.owner.present?
    available = available.or(Board.where(owner_id: user.id))

    available
  }

  private

  def generate_slug
    self.slug = SecureRandom.alphanumeric(17) if self.new_record?
  end

  def check_flow
    flows.create unless flows.present?
  end
end
