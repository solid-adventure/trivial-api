class FlowSerializer < ActiveModel::Serializer
  attributes :id, :name
  
  belongs_to :board
  has_many  :stages
  has_many :connections
end
