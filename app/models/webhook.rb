class Webhook < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :source, presence: true

    belongs_to :user
    
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
                    date: Time.parse(key.to_s).strftime("%m/%d/%Y"),
                    count: {}
                })
            else
                count_concat = {}
                count.keys.each do |c|
                    count_concat[c.second] = count[c]
                end
                chart_stats.push({
                    date: Time.parse(key.to_s).strftime("%m/%d/%Y"),
                    count: count_concat
                })
            end
        }
        return chart_stats
    end

    def self.webhook_by_date(index, stats, key)
        count = stats.select{ |w|
            ws = w[0].strftime("%Y-%m-%d");
            ks = Time.parse(key.to_s).strftime("%Y-%m-%d");
            ws == ks
        }
    end
end
