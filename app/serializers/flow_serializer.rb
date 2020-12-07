class FlowSerializer < ActiveModel::Serializer
  attributes :id, :name
  
  has_many  :stages
  has_manny :connections
end
