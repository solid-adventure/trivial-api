class Invoice < ApplicationRecord
  include Ownable
  include Permissible

  audited owned_audits: true
  has_associated_audits

  belongs_to :payee, class_name: 'Organization', foreign_key: 'payee_org_id'
  belongs_to :payor, class_name: 'Organization', foreign_key: 'payor_org_id'
  belongs_to :owner, polymorphic: true
  belongs_to :register
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user
  has_many :invoice_items, dependent: :destroy

  validates :date, presence: true
  validates :currency, presence: true
  validates :total, presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  before_destroy :unassociate_register_items

  def total_matches_items_sum
    calculated_total = invoice_items.sum(&:extended_amount)
    return true if total == calculated_total

    errors.add(:total, "must equal sum of invoice items (#{calculated_total})")
    false
  end

  private

  def unassociate_register_items
    RegisterItem.where(invoice_id: id).update_all(invoice_id: nil)
  end

end
