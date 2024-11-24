class Invoice < ApplicationRecord
  belongs_to :payee, class_name: 'Organization', foreign_key: 'payee_org_id'
  belongs_to :payor, class_name: 'Organization', foreign_key: 'payor_org_id'
  belongs_to :owner, polymorphic: true
  # has_many :invoice_items, dependent: :destroy

  validates :date, presence: true
  validates :currency, presence: true
  validates :total, presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  # validate :total_matches_items_sum

  private

  def total_matches_items_sum
    calculated_total = invoice_items.sum(&:extended_amount)
    if total != calculated_total
      errors.add(:total, "must equal sum of invoice items (#{calculated_total})")
    end
  end
end