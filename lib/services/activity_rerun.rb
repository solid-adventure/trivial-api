# Logging signature
#
# [ActivityRerun] rerun 447662 Started, app_id=0a7f5bc49c8190 start_at=2024-12-02T08:00:00Z end_at=2024-12-03T08:00:00Z
# [ActivityRerun] rerun 447662 872 of 872 activity entries reset
# [ActivityRerun] rerun 447662 Reset step 1 of 4 completed, all activity entries reset
# [ActivityRerun] rerun 447662 Reset step 2 of 4 completed, all register items deleted
# [ActivityRerun] rerun 447662 872 of 872 activities queued
# [ActivityRerun] rerun 447662 Reset step 3 of 4 completed, all activities queued
# [ActivityRerun] rerun 447662 Reset complete. The register will now begin recalculating
#
# << Queued events are processed by trivial-event-consumer, which logs using the same format  >>
#
# [ActivityRerun] rerun 447662 Starting, batch 1 of 9
# ...
# [ActivityRerun] rerun 447662 Completed, batch 9 of 9
# [ActivityRerun] rerun 447662 Reset step 4 of 4 completed, all activities reprocessed

module Services

  class ActivityRerun
    BATCH_SIZE = 1000

    attr_accessor :app, :start_at, :end_at, :logger, :run_id

    def initialize(app:, start_at:, end_at:, run_id:)
      @app = app
      @start_at = start_at
      @end_at = end_at
      @run_id = run_id
      @logger = Rails.logger
    end

    def call
      log_info("Started, app_id=#{app.name} start_at=#{start_at.iso8601} end_at=#{end_at.iso8601}")
      validate_params!
      ActiveRecord::Base.transaction do
        # TODO Create an audit
        unless get_advisory_lock
          log_info("Rerun already in progress, skipping")
          return
        end
        reset_activity_entries
        delete_register_items
        queue_activities_for_rerun
        log_info("Reset complete. The register will now begin recalculating")
        commit_transaction = true
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
      raise "end_at required" unless end_at.present?
      raise "app required" unless app.present?
      raise "app must be an App" unless app.is_a?(App)
    end

    def reset_activity_entries
      to_reset_count = 0
      reset_count = 0
      activity_entries = ActivityEntry
        .where(
          app_id: app.id,
          created_at: start_at..end_at,
          activity_type: 'request',
        )
        to_reset_count = activity_entries.size
        log_info("Activity entries to reset: #{to_reset_count}")
        activity_entries.in_batches(of: BATCH_SIZE) do |activity_entries|
          batch_count = activity_entries.update_all(
            register_item_id: nil,
            diagnostics: nil,
            status: nil,
            duration_ms: nil
          )
          reset_count += batch_count

          log_info("#{reset_count} of #{to_reset_count} activity entries reset")
        end

      log_info("Reset step 1 of 4 completed, all activity entries reset")
      return reset_count
    end

    def delete_register_items
      to_delete_count = 0
      deleted_count = 0
      customer_id_col = register.meta_columns_from_name(['customer_id']).first
      raise "Meta column customer_id required" unless customer_id_col
      register_items = register.register_items
        .where(
          originated_at: start_at..end_at,
          invoice_id: nil
        )
        .where(customer_id_col => customer_ids)
      to_delete_count = register_items.size
      log_info("Register items to delete: #{to_delete_count}")
      register_items.in_batches(of: BATCH_SIZE) do |register_items|
        batch_count = register_items.delete_all
        deleted_count += batch_count
        log_info("#{deleted_count} of #{to_delete_count} register items deleted")
      end

      log_info("Reset step 2 of 4 completed, all register items deleted")
      return deleted_count
    end

    def queue_activities_for_rerun
      key = "app_#{app.id}_rerun_#{run_id}"
      to_queue_count = 0
      queued_count = 0
      activity_entries = ActivityEntry
        .select(:id, :app_id, :created_at)
        .where(app_id: app.id, created_at: start_at..end_at, activity_type: 'request')
        to_queue_count = activity_entries.size
        batch_number = 0
        batch_count = (to_queue_count / BATCH_SIZE.to_f).ceil
        log_info("Activities to queue: #{to_queue_count}")
        activity_entries.in_batches(of: BATCH_SIZE) do |activity_entries|
          batch_number += 1
          payload = {
            activity_entry_ids: activity_entries.collect(&:id),
            message: "rerun #{run_id} batch #{batch_number} of #{batch_count}",
            run_id:,
            batch_number:,
            batch_count:,
            key:,
          }
          KAFKA.produce_sync(
            topic: Services::Kafka.topic,
            payload: payload.to_json,
            key: key
          )
          queued_count += activity_entries.size
        log_info("#{queued_count} of #{to_queue_count} activities queued")
        end
        log_info("Reset step 3 of 4 completed, all activities queued")
        return queued_count
    end

    def log_info(message)
      logger.info("[ActivityRerun] rerun #{run_id} #{message}")
    end

    def register
      org = @app.owner
      @register ||= org.owned_registers.find_by_name("Income Account")
      raise "Register not found" unless @register
      @register
    end

    def customer_ids
      @customer_ids ||= @app.tags.where(context: "customer_id").pluck(:name).uniq
    end

  end # class ActivityRerun
end # module Services