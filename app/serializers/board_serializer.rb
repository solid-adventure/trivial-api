class BoardSerializer < ActiveModel::Serializer
  attributes  :id, :name, :access_level, :slug, :contents, :description

  belongs_to :owner
  has_many  :flows
end
