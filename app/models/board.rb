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

  def generate_slug
    self.slug = SecureRandom.hex if self.new_record?
    generate_slug if self.class.where.not(id: self.id).exists?(slug: slug)
  end
end
