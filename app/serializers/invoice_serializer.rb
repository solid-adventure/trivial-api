class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :owner_type, :owner_id, :payee, :payor, :date, :notes, :currency, :total, :created_at, :updated_at
  has_many :invoice_items

  def payee
    {
      id: object.payee.id,
      name: object.payee.name
    }
  end

  def payor
    {
      id: object.payor.id,
      name: object.payor.name
    }
  end
end
