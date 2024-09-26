require 'uri'
require 'net/http'
require 'search'

class ActivityEntry < ApplicationRecord
  include Search
  SEARCHABLE_COLUMNS = %w[ payload diagnostics status register_item_id ].freeze

  validates :source, presence: true, if: :is_request?

  belongs_to :app
  belongs_to :register_item, optional: true
  belongs_to :owner, polymorphic: true

  before_create :generate_update_id

  scope :requests, -> { where(activity_type: 'request') }
  scope :updatable, -> {
    where(activity_type: 'request', status: [nil, ''])
    .where.not(update_id: nil)
  }

  def app_runner_service
    self.class.app_runner_service
  end

  def self.app_runner_service
    ENV['DEFAULT_APP_RUNNER_SERVICE'] || 'webhook'
  end

  def is_request?
    activity_type == 'request'
  end

  def app_uri
    uri = URI(app.url)
    uri + webhook_path
  end

  def webhook_path
    manifest = ActiveSupport::JSON.decode(
      app.manifests.order(created_at: :desc).first.try(:content) || 'null'
    )
    manifest.try(:[], 'listen_at').try(:[], 'path') || '/webhooks/receive'
  end

  def resend_webhook
    res = ActivityEntry.post app_uri, payload.to_json,
      'Content-Type' => 'application/json',
      'X-Trivial-Original-Id' => id.to_s
  end

  def resend_kafka
    self.class.kafka.produce_sync(topic: Services::Kafka.topic, payload: payload.to_json, key: payload["key"])
    return OpenStruct.new(code: 200, message: 'OK')
  end

  def resend
    case app_runner_service
    when 'webhook'
      resend_webhook
    when 'kafka'
      resend_kafka
    else
      raise "Invalid service: #{app_runner_service}"
    end
  end

  def publish_receipt!
    ActivityEntry.redis_client.publish "#{app.name}.webhook", id if ActivityEntry.publish_enabled?
  end

  def legacy_attributes
    {
      id: self.id,
      owner_id: self.owner_id,
      owner_type: self.owner_type,
      app_id: self.app.name,
      register_item_id: self.register_item_id,
      update_id: self.update_id,
      activity_type: self.activity_type,
      source: self.source,
      status: self.status,
      payload: self.payload,
      diagnostics: self.diagnostics,
      created_at: self.created_at,
      updated_at: self.updated_at
    }
  end

  def activity_attributes
    {
      id: self.id,
      owner_id: self.owner_id,
      owner_type: self.owner_type,
      app_id: self.app.name,
      register_item_id: self.register_item_id,
      activity_type: self.activity_type,
      source: self.source,
      status: self.status,
      duration_ms: self.duration_ms,
      payload: self.payload,
      diagnostics: self.diagnostics,
      created_at: self.created_at,
      updated_at: self.updated_at
    }
  end

  def generate_update_id
    self.update_id = SecureRandom.uuid if is_request? && update_id.blank? && status.blank?
  end

  def normalize_json
    self.payload = JSON.parse(payload) rescue payload if payload.instance_of?(String)
    self.diagnostics = JSON.parse(diagnostics) rescue diagnostics if diagnostics.instance_of?(String)
  end

  def self.search(entries, search)
    search.each do |hash|
      next unless SEARCHABLE_COLUMNS.include?(hash['c'])
      query = create_query(hash['c'], hash['o'], hash['p'])
      entries = entries.where(query)
    end
    return entries
  end

  def self.send_new_webhook(app, payload)
    entry = ActivityEntry.new app: app
    res = post entry.app_uri, payload,
      'Content-Type' => 'application/json'
  end

  def self.send_new_kafka(app, payload)
    KAFKA.produce_sync(topic: Services::Kafka.topic, payload: payload, key: JSON.parse(payload)["key"])
    return OpenStruct.new(code: 200, message: 'OK')
  end

  def self.send_new(app, payload)
    case app_runner_service
    when 'webhook'
      send_new_webhook(app, payload)
    when 'kafka'
      send_new_kafka(app, payload)
    else
      raise "Invalid service: #{app_runner_service}"
    end
  end

  def self.publish_enabled?
    ENV.has_key?('REDIS_URL')
  end

  def self.redis_client
    @redis_client ||= publish_enabled? ? Redis.new : nil
  end

  def self.post uri, payload, headers
    Net::HTTP.post uri, payload, headers
  end

  def self.chart_stats(app_id, number_of_days)
    return self.get_chart_stats(app_id,number_of_days)
  end

  private

  def self.get_chart_stats(app_id, number_of_days)
    stats = ActivityEntry.requests.where("app_id = ? AND created_at > ?", app_id, number_of_days.days.ago).group("DATE_TRUNC('day', created_at)").group(:status).count(:all)
    self.format_chart_stats(stats, number_of_days)
  end

  def self.format_chart_stats(stats, number_of_days)
    chart_stats = []
    (0..number_of_days-1).each {|i|
      key = Time.parse((Date.today - i.days).to_s)
      count = self.webhook_by_date(i, stats, key)
      if count.empty?
        chart_stats.push({
          date: key.strftime("%m/%d/%Y"),
          count: {}
        })
      else
        count_concat = {}
        count.keys.each do |c|
          count_concat[c.second] = count[c]
        end
        chart_stats.push({
          date: key.strftime("%m/%d/%Y"),
          count: count_concat
        })
      end
    }
    return chart_stats
  end

  def self.webhook_by_date(index, stats, key)
    count = stats.select{ |w|
      ws = w[0].strftime("%Y-%m-%d");
      ks = key.strftime("%Y-%m-%d");
      ws == ks
    }
  end
end
