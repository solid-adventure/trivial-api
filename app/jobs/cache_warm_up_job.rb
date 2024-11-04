# app/jobs/cache_warm_up_job.rb
class CacheWarmUpJob < ApplicationJob
  queue_as :default

  def perform(cache_name:, options: {})
    case cache_name
    when 'app_activity_stats'
      warm_up_app_activity_stats(**options)
    when 'chart_reports'
      warm_up_chart_reports(**options)
    else
      puts("CacheWarmUpJob invalid cache_name: #{cache_name}. Exiting.")
      return
    end

    puts("CacheWarmUpJob all jobs successful. Exiting.")
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
      puts("CacheWarmUpJob warming up app_activity_stats cache with #{app_ids.size} apps and cutoff date #{date_cutoff}")
      App.cache_stats_for!(app_ids:, date_cutoff:)
      puts("CacheWarmUpJob completed for app_activity_stats")
    end
  end

  def warm_up_chart_reports(chart_ids: Chart.pluck(:id), delay_duration: rand(0..900))
    raise 'chart_ids for chart_reports must be an array of integers' unless chart_ids.is_a? Array

    puts("CacheWarmUpJob Warm up chart_reports will start after #{delay_duration} seconds") if delay_duration > 0
    sleep(delay_duration)

    Timeout.timeout(2.hours) do
      puts("CacheWarmUpJob warming up report_charts with #{chart_ids.size} charts")
      report = Services::Report.new()
      charts = Chart.where(id: chart_ids) || []
      charts.each do |chart|
        group_by = chart.aliased_groups.reject{ |k, v| !v }.keys
        group_by_period = chart.report_period
        invert_sign = chart.invert_sign
        register_id = chart.register_id
        chart.default_timezones.each do |timezone|
          report_params = chart.time_range_bounds.merge({
            group_by:,
            group_by_period:,
            invert_sign:,
            register_id:,
            timezone:
          })
          report.send(chart.report_type, report_params)
        end
      end
      puts("CacheWarmUpJob completed warmup for all charts")
    end
  end
end
