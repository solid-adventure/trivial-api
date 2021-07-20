require 'uri'
require 'net/http'

class Webhook < ApplicationRecord
    POLL_DELAY = 2
    MAX_POLL_TIME = 30

    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :source, presence: true

    belongs_to :user

    def app_uri
      uri = URI(base_webhook_url)
      uri.hostname = "#{app_id.to_s.downcase}.#{uri.hostname}"
      uri
    end

    def resend
      res = Net::HTTP.post app_uri, payload,
        'Content-Type' => 'application/json',
        'X-Trivial-Original-Id' => id.to_s
    end

    def self.send_new(app, payload)
      webhook = Webhook.new app_id: app.name
      res = Net::HTTP.post webhook.app_uri, payload,
        'Content-Type' => 'application/json'
    end

    def self.wait_for_newer(user, app_id, last_seen_id = nil)
      matches = []
      start = Time.now

      while matches.empty? && Time.now - start < MAX_POLL_TIME
        self.uncached do
          query = self.select(:id).where(user_id: user.id, app_id: app_id)
          query = query.where('id > ?', last_seen_id) if last_seen_id.present?
          matches = query.order(created_at: :desc).to_a # run the query only once
        end
        sleep POLL_DELAY if matches.empty?
      end

      matches
    end

    def self.chart_stats(app_id, number_of_days)
        return self.get_chart_stats(app_id,number_of_days)
    end

    private

    def self.get_chart_stats(app_id, number_of_days)
        stats = Webhook.where("app_id = ? AND created_at > ?", app_id, number_of_days.days.ago).group("DATE_TRUNC('day', created_at)").group(:status).count(:all)
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

    def base_webhook_url
      ENV['BASE_WEBHOOK_URL'] || 'https://trivialapps.io/webhooks/receive'
    end
end
