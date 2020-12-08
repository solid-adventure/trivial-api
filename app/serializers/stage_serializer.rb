class StageSerializer < ActiveModel::Serializer
 attributes :id, :name

 belongs_to :flow
 has_many :connections
 has_one :connection
end
