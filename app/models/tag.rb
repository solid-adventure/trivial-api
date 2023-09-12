# We catch on this to make calls like taggable.addTag idempotent.
class TagExists < StandardError
end

class Tag < ApplicationRecord
  belongs_to :taggable, polymorphic: true
  validates :name, uniqueness: { 
    scope: [:taggable_type, :taggable_id, :context] },
    strict: TagExists
end