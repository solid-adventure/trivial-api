class ManifestDraft < ApplicationRecord
  include Ownable
  include Permissible

  audited owned_audits: true

  belongs_to :app
  belongs_to :manifest
  belongs_to :owner, polymorphic: true, inverse_of: :manifest_drafts
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user

  scope :expired, -> { where('expires_at <= ?', Time.now) }
  scope :unexpired, -> { where('expires_at > ?', Time.now) }

  def credentials
    app.credentials.draft_by_token(token)
  end

  def save_credentials!(secret_value)
    value = secret_value.except('$drafts')
    unless value.empty?
      creds = app.credentials
      creds.add_draft(token, expires_at, value)
      creds.save!
    end
  end

  def self.create_for_manifest!(manifest, params)
    self.create!(params) do |draft|
      draft.user = manifest.user
      draft.owner = manifest.owner
      draft.app = manifest.app
      draft.manifest = manifest
      draft.token = SecureRandom.uuid
      draft.expires_at = 1.hour.from_now
    end
  end
end
