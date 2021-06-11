require 'uri'
require 'net/http'

class Webhook < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :source, presence: true

    belongs_to :user

    def app_uri
      uri = URI(base_webhook_url)
      uri.hostname = "#{app_id}.#{uri.hostname}"
      uri
    end

    def resend
      res = Net::HTTP.post app_uri, payload,
        'Content-Type' => 'application/json',
        'X-Trivial-Original-Id' => id.to_s
    end

    private

    def base_webhook_url
      ENV['BASE_WEBHOOK_URL'] || 'http://trivialapps.io/webhooks/receive'
    end

end
