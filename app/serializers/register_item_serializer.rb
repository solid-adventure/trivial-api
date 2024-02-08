class RegisterItemSerializer < ActiveModel::Serializer
  attributes :id, :register_id, :owner_type, :owner_id, :unique_key, :description, :amount, :units, :created_at

  def attributes(*args)
    data = super
    register_meta = object.register.meta.symbolize_keys
    register_meta.values.each do |label|
      data[label] = object.send(label)
    end
    data
  end
end
