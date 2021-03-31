class StageSerializer < ActiveModel::Serializer
 attributes :id, :name, :subcomponents

 belongs_to :flow
end
