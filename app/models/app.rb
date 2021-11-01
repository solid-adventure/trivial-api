class App < ApplicationRecord
  include Discard::Model
  include Suggestable

  MINIMUM_PORT_NUMBER = 3001

  belongs_to :user
  has_many :manifests, foreign_key: :internal_app_id, inverse_of: :app

  validates :name, :port, presence: true, uniqueness: true
  validates :hostname, exclusion: { in: %w(staging www) }
  validates :descriptive_name, presence: true, length: {minimum:3}, uniqueness: true

  before_validation :set_defaults

  def url
    base = URI(App.base_url)
    base.hostname = "#{hostname}.#{domain}"
    base.to_s
  end

  def aws_role
    user.ensure_aws_role!
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

  def self.period_stats(user, interval_name, since_time, until_time)
    rows = connection.exec_query(<<-SQL)
    SELECT
      a.id,
      a.name,
      a.descriptive_name,
      (SELECT MAX(created_at) FROM webhooks WHERE app_id=a.name) AS last_run,
      date_trunc(#{connection.quote interval_name}, w.created_at) AS period,
      COUNT(NULLIF(status::int >= 100 AND status::int < 300, false)) AS successes,
      COUNT(NULLIF(status::int >= 300, false)) AS failures
    FROM apps a
    LEFT OUTER JOIN webhooks w ON
      w.app_id=a.name
      AND date_trunc(#{connection.quote interval_name}, w.created_at) >= #{connection.quote since_time}
      AND date_trunc(#{connection.quote interval_name}, w.created_at) <= #{connection.quote until_time}
    WHERE
      a.user_id = #{connection.quote user.id}
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
