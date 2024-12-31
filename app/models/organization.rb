class Organization < ApplicationRecord
  include Taggable

  audited
  has_associated_audits
  has_owned_audits

  has_many :owned_apps, class_name: 'App', as: :owner
  has_many :owned_manifests, class_name: 'Manifest', as: :owner
  has_many :owned_manifest_drafts, class_name: 'ManifestDraft', as: :owner
  has_many :owned_activity_entries, class_name: 'ActivityEntry', as: :owner
  has_many :owned_credential_sets, class_name: 'CredentialSet', as: :owner
  has_many :owned_registers, class_name: 'Register', as: :owner
  has_many :owned_register_items, class_name: 'RegisterItem', as: :owner
  has_many :owned_dashboards, class_name: 'Dashboard', as: :owner, inverse_of: :owner
  has_many :owned_invoices, class_name: 'Invoice', as: :owner
  has_many :owned_invoice_items, class_name: 'InvoiceItem', as: :owner
  has_many :tags, as: :taggable

  has_many :org_roles, dependent: :destroy
  has_many :users, through: :org_roles

  validates :billing_email, presence: true
  validates :name, presence: true

  after_create :create_default_dashboard
  after_create :create_default_register

  default_scope { order(created_at: :asc) }

  alias_attribute :reference_name, :name

  def admin?(user)
    org_roles.find_by(user: user)&.role == 'admin'
  end

  def all_audits
    audits = super
    audits.or(Audited.audit_class.where(auditable: self.users))
  end

  def owner
    self
  end

  def self.find_or_create_by_customer_id(customer_id)
    org = find_by_customer_id(customer_id)
    org = create_by_customer_id(customer_id) unless org
    org
  end

  def self.find_by_customer_id(customer_id)
    customer_tag = Tag.find_by(context: 'customer_id', name: customer_id, taggable_type: self.name)
    customer_tag ? customer_tag.taggable : nil
  end

  def self.create_by_customer_id(customer_id, get_name_proc: nil)
    name = begin
             get_name_proc&.call(customer_id) || "Customer #{customer_id}"
           rescue StandardError => e
             Rails.logger.warn("Customer name retrieval failed: #{e.message}")
             "Customer #{customer_id}"
           end

    org = Organization.create!(name:, billing_email: 'unknown')
    org.addTag!('customer_id', customer_id)
    org
  end

  private
    def create_default_register
      Register.create!(
          name: 'Sales',
          owner: self,
          meta: {}
      )
    end

    def create_default_dashboard
      Dashboard.create!(
          name: "Default Dashboard",
          owner: self
      )
    end
end
