# app/jobs/cache_warm_up_job.rb
class CacheWarmUpJob < ApplicationJob
  queue_as :default

  def perform(cache_name:, options: {})
    case cache_name
    when 'app_activity_stats'
      warm_up_app_activity_stats(**options)
    else
      puts("CacheWarmUpJob invalid cache_name: #{cache_name}. Exiting.")
      return
    end

    puts("CacheWarmUpJob successful. Exiting.")
  rescue Timeout::Error
    puts("CacheWarmUpJob timed out after 2 hours, cache: #{cache}")
  rescue => e
    puts("CacheWarmUpJob failed: #{e.message}")
  end

  private

  def warm_up_app_activity_stats(app_ids: App.kept.pluck(:id), date_cutoff: Date.today - 7.days, delay_duration: rand(0..900))
    raise 'app_ids for app_activity_stats must be an array of integers' unless app_ids.is_a? Array
    raise 'date_cutoff for app_activity_stats must be a Date type' unless date_cutoff.is_a? Date

    puts("CacheWarmUpJob Warm up app_activity_stats will start after #{delay_duration} seconds") if delay_duration > 0
    sleep(delay_duration) # sleep to decrease DB collisions on multiple Rails instances

    Timeout.timeout(2.hours) do
      puts("CacheWarmUpJob Warming up app_activity_stats cache with #{app_ids.size} apps and cutoff date #{date_cutoff}")
      App.cache_stats_for!(app_ids:, date_cutoff:)
    end
  end
end
