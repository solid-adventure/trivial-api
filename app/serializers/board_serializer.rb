class BoardSerializer < ActiveModel::Serializer
  attributes  :id, :name, :access_level, :slug

  belongs_to :owner
  has_many  :flows
end
