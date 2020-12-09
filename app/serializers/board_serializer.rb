class BoardSerializer < ActiveModel::Serializer
  attributes  :id, :name, :access_level, :slug, :contents

  belongs_to :owner
  has_many  :flows
end
