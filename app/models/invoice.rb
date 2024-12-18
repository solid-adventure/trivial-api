class Invoice < ApplicationRecord
  include Ownable
  include Permissible
  include Search
  SEARCHABLE_COLUMNS = %w[id date payee_org_id payor_org_id]

  audited owned_audits: true
  has_associated_audits

  belongs_to :payee, class_name: 'Organization', foreign_key: 'payee_org_id'
  belongs_to :payor, class_name: 'Organization', foreign_key: 'payor_org_id'
  belongs_to :owner, polymorphic: true
  belongs_to :register
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user
  has_many :invoice_items, dependent: :destroy
  has_many :register_items

  default_scope do
    includes(:payor, :payee)
  end

  validates :date, presence: true
  validates :currency, presence: true
  validates :total, presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  alias_attribute :payee_id, :payee_org_id
  alias_attribute :payor_id, :payor_org_id
  delegate :name, to: :payee, prefix: true, allow_nil: false
  delegate :name, to: :payor, prefix: true, allow_nil: false

  before_destroy :unassociate_register_items

  def self.search(invoices, search)
    search.each do |hash|
      next unless SEARCHABLE_COLUMNS.include?(hash['c'])
      query = create_query(hash['c'], hash['o'], hash['p'])
      invoices = invoices.where(query)
    end
    invoices
  end

  def total_matches_items_sum
    calculated_total = invoice_items.sum(&:extended_amount)
    return true if total == calculated_total

    errors.add(:total, "must equal sum of invoice items (#{calculated_total})")
    false
  end

  private

  def unassociate_register_items
    register_items.update_all(invoice_id: nil)
  end
end
