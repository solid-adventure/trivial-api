# We catch on this to make calls like taggable.addTag idempotent.
class TagExists < StandardError
end

class Tag < ApplicationRecord
  audited associated_with: :taggable, owned_audits: true

  belongs_to :taggable, polymorphic: true

  validates :name, uniqueness: { 
    scope: [:taggable_type, :taggable_id, :context] },
    strict: TagExists

  alias_attribute :reference_name, :name
end
