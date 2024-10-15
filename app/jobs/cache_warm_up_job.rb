# app/jobs/cache_warm_up_job.rb
class CacheWarmUpJob < ApplicationJob
  queue_as :default

  def perform(cache_name:, options: {})
    case cache_name
    when 'app_activity_stats'
      warm_up_app_activity_stats(**options)
    else
      Rails.logger.info("Invalid cache_name: #{cache_name}. Exiting.")
      return
    end

    Rails.logger.info("Cache warm up successful. Exiting.")
  rescue Timeout::Error
    Rails.logger.error("CacheWarmupJob timed out after 2 hours, cache: #{cache}")
  rescue => e
    Rails.logger.error("CacheWarmUpJob failed: #{e.message}")
  end

  private

  def warm_up_app_activity_stats(app_ids: App.kept.pluck(:id), date_cutoff: Date.today - 7.days)
    raise 'app_ids must be an array of integers' unless app_ids.is_a? Array
    raise 'date_cutoff must be a Date type' unless date_cutoff.is_a? Date

    sleep(rand(0..5400)) # sleep up to 1.5 hours to decrease DB collisions on multiple Rails instances

    Timeout.timeout(2.hours) do
      Rails.logger.info("Warming up app_activity_stats cache with #{app_ids.size} apps and cutoff date #{date_cutoff}")
      App.cache_stats_for!(app_ids:, date_cutoff:)
    end
  end
end
