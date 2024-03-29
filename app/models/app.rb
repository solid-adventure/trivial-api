class App < ApplicationRecord
  include Discard::Model
  include Suggestable
  include Taggable
  include Ownable
  include Permissible

  MINIMUM_PORT_NUMBER = 3001

  audited
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

  def self.hourly_stats(user)
    period_stats user, 'minute', 1.hour.ago.beginning_of_minute, Time.now.utc.beginning_of_minute
  end

  def self.daily_stats(user)
    period_stats user, 'hour', 1.day.ago.beginning_of_hour, Time.now.utc.beginning_of_hour
  end

  def self.weekly_stats(user)
    period_stats user, 'day', 1.week.ago.beginning_of_day, Time.now.utc.beginning_of_day
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

  private

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

  #FIXME as part of ownership functionality change
  def self.period_stats(user, interval_name, since_time, until_time)
    rows = connection.exec_query(<<-SQL)
    SELECT
      a.id,
      a.name,
      a.descriptive_name,
      (SELECT MAX(created_at) FROM activity_entries WHERE app_id=a.id) AS last_run,
      date_trunc(#{connection.quote interval_name}, w.created_at) AS period,
      COUNT(NULLIF(status::int >= 100 AND status::int < 300, false)) AS successes,
      COUNT(NULLIF(status::int >= 300, false)) AS failures
    FROM apps a
    LEFT OUTER JOIN activity_entries w ON
      w.app_id=a.id
      AND w.activity_type='request'
      AND date_trunc(#{connection.quote interval_name}, w.created_at) >= #{connection.quote since_time}
      AND date_trunc(#{connection.quote interval_name}, w.created_at) <= #{connection.quote until_time}
    WHERE
      a.owner_id = #{connection.quote user.id}
      AND a.owner_type = 'User'
      AND a.discarded_at IS NULL
    GROUP BY a.id, a.name, a.descriptive_name, period, last_run
    ORDER BY a.descriptive_name, a.id, period
    SQL

    out = []
    curr = nil

    rows.each do |row|
      if curr.nil? || curr[:id] != row['id']
        curr = {
          id: row['id'],
          name: row['name'],
          descriptive_name: row['descriptive_name'],
          last_run: row['last_run'],
          stats: []
        }
        out << curr
      end
      curr[:stats] << {
        period: row['period'],
        successes: row['successes'],
        failures: row['failures']
      } unless row['period'].nil?
    end

    {start_range: since_time, end_range: until_time, stats: out}
  end
end
