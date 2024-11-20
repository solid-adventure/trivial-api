class App < ApplicationRecord
  include Discard::Model
  include Suggestable
  include Taggable
  include Ownable
  include Permissible

  MINIMUM_PORT_NUMBER = 3001

  audited owned_audits: true
  has_associated_audits

  belongs_to :owner, polymorphic: true
  has_many :permissions, as: :permissible
  has_many :permitted_users, through: :permissions, source: :user
  has_many :manifests, foreign_key: :internal_app_id, inverse_of: :app
  has_many :activity_entries, inverse_of: :app
  has_many :tags, as: :taggable

  validates :name, :port, presence: true, uniqueness: true
  validates :hostname, exclusion: { in: %w(staging www) }
  validates :descriptive_name, presence: true, length: {minimum:3}
  validate :descriptive_name_unique?

  # This is over simplified, but allows guest users to view public apps when no user is present
  scope :publicReadable, -> { where(readable_by: 'public') }

  before_validation :set_defaults

  def descriptive_name_unique?
    # custom validator to factor for deleted apps
    if owner
      unique = owner.owned_apps.kept.where(descriptive_name: descriptive_name).where.not(id: id).size == 0
    else 
      return false
    end
    if !unique
      errors.add(:descriptive_name, "has already been taken")
    end
  end

  def url
    base = URI(App.base_url)
    base.hostname = "#{hostname}.#{domain}"
    base.to_s
  end

  # returns nil for Organization owners
  def aws_role
    owner.try(:ensure_aws_role!)
  end

  def credentials
    @credentials ||= Credentials.find_or_build_by_app_and_name self, credentials_name
  end

  def api_keys
    @api_keys ||= ApiKeys.new(app: self)
  end

  def self.default_domain
    URI(App.base_url).hostname
  end

  def self.default_load_balancer
    ENV['DEFAULT_LOAD_BALANCER'] || 'staging-lb'
  end

  def self.base_url
    ENV['BASE_URL'] || 'https://staging.trivialapps.io'
  end

  def copy!(new_user=nil, descriptive_name)
    new_app = self.dup
    new_app.unset_defaults
    new_app.owner = new_user if new_user
    new_app.descriptive_name = descriptive_name
    if new_app.save!
      manifest = self.manifests.order("created_at DESC").first
      manifest.copy_to_app!(new_app) if manifest
      self.copyTagsTo(new_app)
    end
    return new_app
  end

  def unset_defaults
    %w(name port hostname domain load_balancer).each do |attr|
      self[attr] = nil
    end
  end

  # overwrites Ownable method
  def transfer_ownership(new_owner:, revoke: false)
    super(new_owner: new_owner, revoke: revoke)

    manifests.update_all(owner_id: new_owner.id, owner_type: new_owner.class.name)
    activity_entries.update_all(owner_id: new_owner.id, owner_type: new_owner.class.name)
  end

  def self.get_activity_stats_for(app_names:, date_cutoff:)
    return [] if app_names.empty?
    app_name_to_id = App.where(name: app_names).pluck(:name, :id).to_h
    app_ids = app_name_to_id.values

    cached_stats = cached_stats(app_ids:, date_cutoff:)
    uncached_app_ids = app_ids - cached_stats.keys
    newly_cached_stats = cache_stats_for!(app_ids: uncached_app_ids, date_cutoff:)
    cached_stats.merge!(newly_cached_stats)

    uncached_stats = uncached_stats_for(app_ids:)

    app_names.map do |app_name|
      app_id = app_name_to_id[app_name]
      stats = cached_stats[app_id] + uncached_stats[app_id]
      { app_id: app_name, stats: }
    end
  end

  private
  @cache_date_cutoff = Date.today

  def self.cache_key_for(app_id:, date_cutoff:)
    "app_activity_stats/#{app_id}/#{date_cutoff}"
  end

  def self.cached_stats(app_ids:, date_cutoff:)
    cached_stats = {}
    app_ids.each do |app_id|
      cache_key = cache_key_for(app_id:, date_cutoff:)
      if cached_data = Rails.cache.read(cache_key)
        cached_stats[app_id] = cached_data
      end
    end
    cached_stats
  end

  def self.cache_stats_for!(app_ids:, date_cutoff:)
    time_range = (date_cutoff.to_time..@cache_date_cutoff.to_time)
    included_dates = (date_cutoff...@cache_date_cutoff).to_a
    activity_stats = stats_for(app_ids:, time_range:, included_dates:)

    activity_stats.each do |app_id, stats_array|
      cache_key = cache_key_for(app_id:, date_cutoff:)
      expires_in = (Time.now.end_of_day - Time.now).seconds
      Rails.cache.write(cache_key, stats_array, expires_in:)
    end
  end

  def self.uncached_stats_for(app_ids:)
    time_range = (@cache_date_cutoff.to_time..)
    included_dates = (@cache_date_cutoff..Date.today).to_a
    stats_for(app_ids:, time_range:, included_dates:)
  end

  def self.stats_for(app_ids:, time_range:, included_dates:)
    return {} if app_ids.blank?
    activity_groups = activity_groups_for(app_ids:, time_range:)
    format_activity(activity_groups:, app_ids:, included_dates:)
  end

  def self.activity_groups_for(app_ids:, time_range:)
    ActivityEntry.requests
      .where(app_id: app_ids, created_at: time_range)
      .group(:app_id, "created_at::date", :status)
      .count
  end

  def self.format_activity(activity_groups:, app_ids:, included_dates:)
    included_dates_hash = included_dates.to_h do |date|
      [date, { date:, count: {} }]
    end

    results = app_ids.to_h do |app_id|
      [app_id, included_dates_hash.deep_dup]
    end

    activity_groups.each do |(app_id, date, status), value|
      results[app_id][date][:count][status] = value
    end

    results.transform_values!(&:values)
  end

  def credentials_name
    "credentials/#{name}"
  end

  def set_defaults
    self.name = random_name unless name.present?
    self.port = next_available_port unless port.present?
    self.hostname = name.to_s.downcase unless hostname.present?
    self.domain = App.default_domain unless domain.present?
    self.load_balancer = App.default_load_balancer unless load_balancer.present?
  end

  def random_name
    proposed = SecureRandom.hex(7)
    App.where(name: proposed).size > 0 ? random_name : proposed
  end

  def next_available_port
    App.maximum(:port).try(:next) || MINIMUM_PORT_NUMBER
  end
end
