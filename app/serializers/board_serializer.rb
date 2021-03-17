class BoardSerializer < ActiveModel::Serializer
  attributes  :id, :name, :access_level, :slug, :contents, :description. :meta_description, :featured

  belongs_to :owner
  has_many  :flows
end
