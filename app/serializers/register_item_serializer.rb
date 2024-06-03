class RegisterItemSerializer < ActiveModel::Serializer
  attributes :id, :register_id, :owner_type, :owner_id, :unique_key, :description, :amount, :units, :originated_at, :created_at

  def attributes(*args)
    data = super
    return data unless object.register_id

    Register.where(id: object.register_id).pick(:meta).each do |column, label|
      data[label] = object[column]
    end

    data
  end
end
