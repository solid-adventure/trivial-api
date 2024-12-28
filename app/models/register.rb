class Register < ApplicationRecord

  include Ownable
  include Permissible

  audited owned_audits: true
  has_associated_audits

  # Register identity basics
  validates :name, presence: true, uniqueness: { scope: :owner }
  validates :sample_type, acceptance: { accept: ['series', 'increment'] }
  validates :owner, presence: true

  # Expected values for items, denormalized to register_items
  validates :units, presence: true

  # Ownership and permissions
  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  has_many :register_items, dependent: :destroy
  has_many :charts, dependent: :destroy, inverse_of: :register

  before_validation :set_defaults
  after_create :create_gross_revenue_chart

  alias_attribute :reference_name, :name

  def meta_columns_from_name(column_labels)
    meta = self.meta.invert
    meta_columns_from_name = column_labels.map do |column|
      meta.fetch(column) { |c| raise ArgumentError, "Invalid column_labels #{c} is not a meta-column for register" }
    end
  end

  private
    def set_defaults
      self.sample_type ||= 'increment'
      self.units ||= 'units'
    end

    def create_gross_revenue_chart
      return unless owner_type == 'Organization'
      Chart.create!(
        {
          dashboard_id: owner.owned_dashboards.first.id,
          register_id: id,
          name: "Gross Revenue",
          report_period: 'month',
          meta0: meta.key?('meta0') ? false : nil,
          meta1: meta.key?('meta1') ? false : nil,
          meta2: meta.key?('meta2') ? false : nil,
          meta3: meta.key?('meta3') ? false : nil,
          meta4: meta.key?('meta4') ? false : nil,
          meta5: meta.key?('meta5') ? false : nil,
          meta6: meta.key?('meta6') ? false : nil,
          meta7: meta.key?('meta7') ? false : nil,
          meta8: meta.key?('meta8') ? false : nil,
          meta9: meta.key?('meta9') ? false : nil,
        }
      )
    end
end
