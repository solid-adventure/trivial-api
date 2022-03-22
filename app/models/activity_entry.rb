require 'uri'
require 'net/http'

class ActivityEntry < ApplicationRecord

    validates :source, presence: true, if: :is_request?

    belongs_to :user
    belongs_to :app

    before_create :generate_update_id

    scope :requests, -> { where(activity_type: 'request') }
    scope :updatable, -> {
      where(activity_type: 'request', status: [nil, ''])
      .where.not(update_id: nil)
    }

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

    def resend
      res = ActivityEntry.post app_uri, payload.to_json,
        'Content-Type' => 'application/json',
        'X-Trivial-Original-Id' => id.to_s
    end

    def publish_receipt!
      ActivityEntry.redis_client.publish "#{app.name}.webhook", id if ActivityEntry.publish_enabled?
    end

    def legacy_attributes
      {
        id: self.id,
        user_id: self.user_id,
        app_id: self.app.name,
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
        user_id: self.user_id,
        app_id: self.app.name,
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

    def self.send_new(app, payload)
      entry = ActivityEntry.new app: app
      res = post entry.app_uri, payload,
        'Content-Type' => 'application/json'
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
end
