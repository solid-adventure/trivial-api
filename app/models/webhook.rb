class Webhook < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :source, presence: true

    belongs_to :user
    
    def self.chart_stats(app_id, number_of_days)
        # TODO confirm stored timestamp timezone is same as generated timestamp here
        @_chart_stats = []
        self.get_chart_stats(app_id,number_of_days)
        self.format_chart_stats(number_of_days)
        return @_chart_stats
    end

    def self.get_chart_stats(app_id, number_of_days)
        puts Time.now-number_of_days.days
        @_stats = Webhook.where("app_id = ? AND created_at > ?", app_id, Time.now.utc-number_of_days.days).group("DATE_TRUNC('day', created_at)").group(:status).size
    end

    def self.format_chart_stats(number_of_days)
        (0..number_of_days-1).each {|i|
            webhook_logged = self.webhook_by_date(i)
            if webhook_logged
                @_chart_stats.push({
                    date: Time.parse(@_key.to_s).strftime("%Y-%m-%d"),
                    count: {}
                })
            else
                count_concat = {}
                @_count.keys.each do |c|
                    count_concat[c.second] = @_count[c]
                end
                @_chart_stats.push({
                    date: Time.parse(@_key.to_s).strftime("%Y-%m-%d"),
                    count: count_concat
                })
            end
        }
    end

    def self.webhook_by_date(index)
        @_key = Time.parse((Date.today - index.days).to_s)
        @_count = @_stats.select{ |w|
            ws = Time.parse(w[0].to_s).strftime("%Y-%m-%d");
            ks = Time.parse(@_key.to_s).strftime("%Y-%m-%d");
            ws == ks
        }
        @_count.empty? ? true : false
    end
end
