# Usage:
# ActivityRerun.new(app, start_at).call

# Logging signature:
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Reun started
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Register items deleted. count=1500
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Activity entries reset. count=1500
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Queueing activities. total=10000
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Batch processed. processed=2000 total=10000
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Activities queued. count=10000
# [ActivityRerun] app_id=123 start_at=2024-11-14T10:00:00Z Reun completed. deleted=1500 reset=1500 reprocessed=10000

module Services

  class ActivityRerun
    BATCH_SIZE = 1000

    attr_accessor :app, :start_at, :logger, :last_id, :run_id

    def initialize(app, start_at)
      @app = app
      @start_at = start_at
      @logger = Rails.logger
      @last_id = nil
      @run_id = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
    end

    def call
      log_info("Reun started")
      validate_params!
      ActiveRecord::Base.transaction do
        # TODO Create an audit
        unless get_advisory_lock
          log_info("Rerun already in progress, skipping")
          return
        end
        reset_count = reset_activity_entries
        deleted_count = delete_register_items
        queued_count = queue_activities_for_reun
        log_info("Reun completed. register_items_deleted=#{deleted_count} activities_reset=#{reset_count} queued=#{queued_count}")
        return true
      end
    end

    private

    def lock_key
      "rerun_app_#{@app.id}"
    end

    # Prevent multiple instances from running at the same, per app/contract
    def get_advisory_lock
      ActiveRecord::Base.connection.select_value(<<-SQL)
        SELECT pg_try_advisory_xact_lock(#{Zlib.crc32(lock_key)})
      SQL
    end

    def validate_params!
      raise "start_at required" unless start_at.present?
      raise "app required" unless app.present?
      raise "app must be an App" unless app.is_a?(App)
    end

    def delete_register_items
      total_count = 0

       RegisterItem
        .where(
          app_id: app.id,
          originated_at: start_at..,
          invoice_id: nil
        )
      .in_batches(of: BATCH_SIZE) do |register_items|

        # We'll do a full reset of the activity in a separate step, but we need to dissassociate the register items
        # from the activity entries first, to satisfy the foriegn key constraint.
        # We do this in a separate step because there isn't a 1:1 between activities and register_items
        ActivityEntry.where(register_item_id: register_items.pluck(:id))
        .update_all(register_item_id: nil)
        batch_count = register_items.delete_all
        total_count += batch_count

        log_info("Register items batch deleted. batch_count: #{batch_count}, total_count: #{total_count}")
      end

      log_info("Register items deleted. count=#{total_count}")
      total_count
    end

    def reset_activity_entries
      total_count = 0
      ActivityEntry
        .where(
          app_id: app.id,
          created_at: start_at..,
          activity_type: 'request',
        )
        .where.not(register_item_id: nil)
        .in_batches(of: BATCH_SIZE) do |activity_entries|
          batch_count = activity_entries.update_all(
            register_item_id: nil,
            diagnostics: nil,
            status: nil,
            duration_ms: nil
          )
          total_count += batch_count

          log_info("Activity entries batch reset. batch_count: #{batch_count}, total_count: #{total_count}")
        end

      log_info("Activity entries reset. count=#{total_count}")
      total_count
    end

    def queue_activities_for_reun
      key = "app_#{app.id}_rerun_#{run_id}"
      queued_count = 0
      ActivityEntry
        .select(:id, :app_id, :created_at)
        .where(app_id: app.id, created_at: start_at.., activity_type: 'request')
        .in_batches(of: BATCH_SIZE) do |activity_entries|
          payload = {
            activity_entry_ids: activity_entries.collect(&:id),
            key: key,
          }
          KAFKA.produce_sync(
            topic: Services::Kafka.topic,
            payload: payload.to_json,
            key: key
          )
          queued_count += activity_entries.size
          @last_id = activity_entries.last.id
        end
        log_info("Activities queued. count=#{queued_count}")
        return queued_count
      rescue StandardError => e
        log_info("Requeing failed. last_id=#{last_id}")
        puts e.message
        puts e.backtrace.join("\n")
        raise
    end

    def log_info(message)
      logger.info("[ActivityRerun] run_id=#{run_id} app_id=#{app.name} start_at=#{start_at.iso8601} #{message}")
    end

  end # class ActivityRerun
end # module Services