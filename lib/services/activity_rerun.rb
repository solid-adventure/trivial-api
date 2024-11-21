# Logging signature:
# [ActivityRerun] run_id=788287 app_id=0a7f5bc49c8190 start_at=2024-10-01T00:00:00-07:00 Rerun started
# [ActivityRerun] run_id=788287 app_id=0a7f5bc49c8190 start_at=2024-10-01T00:00:00-07:00 Activity entries reset. count=0
# [ActivityRerun] run_id=788287 app_id=0a7f5bc49c8190 start_at=2024-10-01T00:00:00-07:00 Register items deleted. count=0
# [ActivityRerun] run_id=788287 app_id=0a7f5bc49c8190 start_at=2024-10-01T00:00:00-07:00 Activities queued. count=19392
# [ActivityRerun] run_id=788287 app_id=0a7f5bc49c8190 start_at=2024-10-01T00:00:00-07:00 Rerun completed. register_items_deleted=0 activities_reset=0 queued=19392

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

    def call(&block)
      log_info("Rerun started", &block)
      validate_params!
      ActiveRecord::Base.transaction do
        # TODO Create an audit
        unless get_advisory_lock
          log_info("Rerun already in progress, skipping", &block)
          return
        end
        reset_count = reset_activity_entries(&block)
        deleted_count = delete_register_items(&block)
        queued_count = queue_activities_for_rerun(&block)
        log_info("Rerun cleanup and re-queuing completed. The register will now begin recalculating. register_items_deleted=#{deleted_count} activities_reset=#{reset_count} queued=#{queued_count}", &block)
        true
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

    def delete_register_items(&block)
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

        log_info("Register items batch deleted. batch_count: #{batch_count}, total_count: #{total_count}", &block)
      end

      log_info("Register items deleted. count=#{total_count}", &block)
      total_count
    end

    def reset_activity_entries(&block)
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

          log_info("Activity entries batch reset. batch_count: #{batch_count}, total_count: #{total_count}", &block)
        end

      log_info("Activity entries reset. count=#{total_count}", &block)
      total_count
    end

    def queue_activities_for_rerun(&block)
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
        log_info("Activities batch queued. count=#{queued_count}", &block)
        end
        log_info("All Activities queued. count=#{queued_count}", &block)
        queued_count
      rescue StandardError => e
        log_info("Requeing failed. last_id=#{last_id}", &block)
        puts e.message
        puts e.backtrace.join("\n")
        raise
    end

    def log_info(message, &block)
      logger.info("[ActivityRerun] run_id=#{run_id} app_id=#{app.name} start_at=#{start_at.iso8601} #{message}")
      yield({run_id: run_id, app_id: app.name, start_at: start_at.iso8601, message: }) if block_given?
    end

  end # class ActivityRerun
end # module Services