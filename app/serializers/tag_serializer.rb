class TagSerializer < ActiveModel::Serializer
  attributes :id, :context, :name, :taggable_type, :taggable_id, :created_at, :updated_at
end
