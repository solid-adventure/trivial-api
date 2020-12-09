class StageSerializer < ActiveModel::Serializer
 attributes :id, :name, :subcomponents

 belongs_to :flow
 has_many :connections
 has_one :connection
end
