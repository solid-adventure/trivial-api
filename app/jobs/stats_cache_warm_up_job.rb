# app/jobs/stats_cache_warm_up_job.rb
class StatsCacheWarmUpJob < ApplicationJob
  queue_as :default

  def perform(app_ids: App.pluck(:id), date_cutoff: Date.today - 7.days)
    raise 'app_ids must be an array of integers' unless app_ids.is_a? Array
    raise 'date_cutoff must be a Date type' unless date_cutoff.is_a? Date

    sleep(rand(0..5400)) # sleep up to 1.5 hours to decrease DB collisions on multiple Rails instances

    Timeout.timeout(2.hours) do
      Rails.logger.info("Starting StatsCacheWarmUp with #{app_ids.size} apps and cutoff date #{date_cutoff}")
      App.cache_stats_for!(app_ids:, date_cutoff:)
      Rails.logger.info("Finished StatsCacheWarmUp successfully")
    end
  rescue Timeout::Error
    Rails.logger.error("StatsCacheWarmupJob timed out after 2 hours")
  rescue => e
    Rails.logger.error("StatsCacheWarmUpJob failed: #{e.message}")
  end
end
