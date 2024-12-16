class InvoiceItem < ApplicationRecord
  include Ownable

  audited associated_with: :invoice, owned_audits: true

  belongs_to :invoice
  belongs_to :owner, polymorphic: true
  has_many :register_items

  scope :with_invoice, -> { includes(:invoice) }

  validates :quantity, presence: true,
            numericality: { greater_than: 0 }
  validates :unit_price, presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  # validates :income_account, presence: true

  private

  def calculate_extended_amount
    return if quantity.nil? || unit_price.nil?
    errors.add(:extended_amount, "cannot be set directly") if extended_amount.present?
    self.extended_amount = quantity * unit_price
  end
end
