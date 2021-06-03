class Webhook < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :source, presence: true

    belongs_to :user
    
    def self.get_chart_stats(app_id)
        webhooks = Webhook.where(app_id: app_id)
        chart_stats = {
            collection: webhooks.group(:id, :status),
            total: webhooks.count,
            status_count: webhooks.group(:status).count
        }
        return chart_stats
    end
end
