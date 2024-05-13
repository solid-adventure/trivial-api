class RegisterItemSerializer < ActiveModel::Serializer
  attributes :id, :register_id, :owner_type, :owner_id, :unique_key, :description, :amount, :units, :originated_at, :created_at

  @@register_metas = {}

  def attributes(*args)
    data = super
    return data unless object.register_id
    
    unless @@register_metas[object.register_id]
      @@register_metas[object.register_id] = object.register.meta.symbolize_keys
    end
    
    @@register_metas[object.register_id].values.each do |label|
      data[label] = object.send(label)
    end

    data
  end
end
