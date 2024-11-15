# Usage:
# ActivityReprocess.new(app, start_at).call

# Logging signature:
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Reprocessing started
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Register items deleted. count=1500
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Activity entries reset. count=1500
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Queueing activities. total=10000
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Batch processed. processed=2000 total=10000
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Activities queued. count=10000
# [ActivityReprocess] app_id=123 start_at=2024-11-14T10:00:00Z Reprocessing completed. deleted=1500 reset=1500 reprocessed=10000

module Services

  class ActivityReprocess
    BATCH_SIZE = 2000

    def initialize(app, start_at)
      @app = app
      @start_at = start_at
      @logger = Rails.logger
      @last_created_at = nil
    end

    def call
      log_info("Reprocessing started")
      validate_params!

      ActiveRecord::Base.transaction do

        # TODO Create an audit
        # TODO Create a DB lock to prevent multiple reprocesses from happening at the same time

        deleted_count = delete_register_items
        reset_count = reset_activity_entries
        queued_count = queue_activities_for_reprocessing

        # We completed resending them; from a user perspective, the doesn't complete until the stream is finished processing
        log_info("Reprocessing completed. register_items_deleted=#{deleted_count} activities_reset=#{reset_count} queued=#{queued_count}")
      end
    end

    private

    attr_reader :app, :start_at, :logger, :last_created_at

    def validate_params!
      raise "start_at required" unless start_at.present?
      raise "app required" unless app.present?
    end

    def delete_register_items
      count = RegisterItem
        .where(
          app_id: app.id,
          originated_at: start_at..,
          invoice_id: nil
        )
        .delete_all

      log_info("Register items deleted. count=#{count}")
      count
    end

    def reset_activity_entries
      count = ActivityEntry
        .where(app_id: app.id, created_at: start_at.., activity_type: 'request')
        .update_all(register_item_id: nil)

      log_info("Activity entries reset. count=#{count}")
      count
    end

    def queue_activities_for_reprocessing
      activities = ActivityEntry
        .select(:id, :app_id, :payload, :created_at)
        .where(app_id: app.id, created_at: start_at.., activity_type: 'request')
        .order(:id)

      total = activities.size
      processed = 0
      log_info("Queueing activities. total=#{total}")

      begin
        activities.find_each(batch_size: BATCH_SIZE) do |activity_entry|
          activity_entry.resend
          processed += 1
          last_created_at = activity_entry.created_at

          if (processed % BATCH_SIZE).zero?
            log_info("Batch added to queue. processed=#{processed} total=#{total}")
          end
        end
      rescue
        log_info("Requeing failed. processed=#{processed} total=#{total}, last_created_at=#{last_created_at}")
      end

      log_info("Activities queued. count=#{processed}")
      processed
    end

    def log_info(message)
      logger.info("[ActivityReprocess] app_id=#{app.name} start_at=#{start_at.iso8601} #{message}")
    end

  end # class ActivityReprocess
end # module Services