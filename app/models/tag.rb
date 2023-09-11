# We catch on this to make calls like taggable.addTag idempotent.
class TagExists < StandardError
end

class Tag < ApplicationRecord
  belongs_to :taggable, polymorphic: true
  validates :name, uniqueness: { 
    scope: [:taggable_type, :taggable_id, :context] },
    strict: TagExists

  def self.ransackable_attributes(auth_object = nil)
    ["context", "name", "taggable_id", "taggable_type"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["taggable"]
  end

end