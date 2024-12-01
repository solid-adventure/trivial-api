namespace :tasks do

  desc "Create invoices for all customers ending on a specific date"
  task :create_invoices, [:end_date, :period, :groups] => :environment do |t, args|
    # Set defaults for optional parameters
    args.with_defaults(
      end_date: Date.current.to_s,
      period: 'month',
      groups: 'customer_id,warehouse_id'
    )

    puts "[create_invoices] Invoice creation started."
    timezones = ["America/New_York", "America/Los_Angeles"]
    registers = Register.all
    report = Services::Report.new()

    group_by = args[:groups].split(',').map(&:strip)

    begin
      end_date = Date.parse(args[:end_date])
    rescue ArgumentError
      raise ArgumentError, "end_date must be a valid date string (e.g., '2024-04-30')"
    end

    ActiveRecord::Base.transaction do
      registers.each do |register|
        if !register.meta.values.include?("customer_id")
          # TEMP
          # puts "[create_invoices] Skipping register, no meta column customer_id: #{register.id}, #{register.name}"
          next
        end

        if !register.meta.values.include?("warehouse_id")
          # TEMP
          # puts "[create_invoices] Skipping register: no meta column warehouse_id: #{register.id}, #{register.name}"
          next
        end

        puts "[create_invoices] Processing register: #{register.id}, #{register.name}"
        timezones.each do |timezone|
          puts "[create_invoices] Processing timezone: #{timezone}"

          # Calculate date range using end_date as the anchor and period for the duration
          timezone_end = end_date.in_time_zone(timezone)

          # Use end_date as the end date (including the full day) and calculate start date based on period
          end_at = timezone_end.end_of_day
          start_at = case args[:period]
          when 'month'
            end_at.beginning_of_month
          when 'week'
            end_at - 1.week
          when 'day'
            end_at - 1.day
          else
            raise ArgumentError, "Unsupported period: #{args[:period]}"
          end

          report_params = {
            register_id: register.id,
            start_at: start_at.iso8601,
            end_at: end_at.iso8601,
            group_by_period: args[:period],
            group_by: group_by,
            timezone: timezone
          }

          result = report.item_sum(report_params)
          puts "[create_invoices] Results for #{timezone}"
          puts result.inspect
        end # timezones.each
      end # registers.each
      true # commit transaction
    end
    puts "[create_invoices] Invoice creation completed."
  end

  # rake tasks:send_new_period_started_events
  desc "Create Kafka events when new billing period is started"
  task :send_new_period_started_events => :environment do
    puts "Producing new period events into kafka topic: #{Services::Kafka.topic}"
  # key = object_verb.customerId
    customer_ids = Tag.where(taggable_type: "App", context: "customer_id").pluck(:name).uniq
    customer_ids.each do |customer_id|
      key = "period.started.#{customer_id}"
      period_start = "#{Date.today.beginning_of_day.utc.iso8601 }" # Midnight UTC
      puts "Sending new period started event. period_start: #{period_start}, customer_id: #{customer_id}"
      payload = {
        "key": key,
        "name": "period.started",
        "period": {
          started_at: period_start
        },
      }
      KAFKA.produce_sync(topic: Services::Kafka.topic, payload: payload.to_json, key: key)
    end
  end

  # rake "tasks:run_scheduled[10 minutes]"
  # rake "tasks:run_scheduled[hour]"
  # rake "tasks:run_scheduled[day]"
  desc "Run apps scheduled for every 10 minutes, hourly, or daily"
  task :run_scheduled, [:interval] => :environment do |t, args|
    interval = args[:interval]
    puts "Starting Scheduled Every #{interval} apps..."
    apps = App.kept.where('schedule @> ?', "{\"every\":\"#{interval}\"}")
    apps.each do |app|
      puts "Running #{app.name}, #{app.descriptive_name}"
      begin 
        res = ActivityEntry.send_new app, app.schedule["payload"].to_json
        puts res
      rescue => e
        puts "Error running #{app.name}, #{app.descriptive_name}: #{e}"
      end
      puts "Completed #{app.name}, #{app.descriptive_name}"
    end
    puts "Completed Scheduled Every #{interval} apps."
  end

  # rake "tasks:reassign_app_owner["123", "456"]"
  desc "Move an app and it's history into a new user account"
  task :reassign_app_owner, [:app_name, :new_user_id] => :environment do |t, args|
    puts "Updating app ownership..."
    puts "Looking up app: #{args[:app_name]}"
    app = App.find_by_name(args[:app_name])
    puts "Found app with descriptive name: #{app.descriptive_name}"
    puts "User ID at start: #{app.user_id}"
    puts "New user ID: #{args[:new_user_id]}"
    puts "Updating ownership..."
    new_owner = User.find(args[:new_user_id])
    app.user = new_owner
    app.save
    app.manifests.update_all(user_id: new_owner.id)
    app.activity_entries.update_all(user_id: new_owner.id)
    Webhook.where(app_id: app.name).update_all(user_id: new_owner.id)
    puts "Done"
  end

  # rake "tasks:cleanup_activity_entries["30"]" this will run in non-destructive preview mode
  # rake "tasks:cleanup_activity_entries["30","false"]" this will actually delete records
  desc "Remove ActivityEntries with no RegisterItem that are older than provided days"
  task :cleanup_activity_entries, [:days_kept, :preview] => :environment do |t, args|
    puts "cleanup_activity_entries task starting."
    raise 'must supply number of days to keep' unless args[:days_kept]
    cutoff_date = Time.now - args[:days_kept].to_i.days
    puts "Preparing to delete ActivityEntries older than #{cutoff_date}."

    preview = ActiveModel::Type::Boolean.new.cast(args[:preview])
    preview = true if preview.nil?
    puts "Preview Mode: #{preview}"

    entries_to_delete = ActivityEntry.where(register_item_id: nil)
                                     .where('created_at < ?', cutoff_date)

    entries_to_keep = ActivityEntry.where('created_at >= ?', cutoff_date)
                                     .or(ActivityEntry.where.not(register_item_id: nil))

    entries_to_delete_count = entries_to_delete.size
    entries_to_keep_count = entries_to_keep.size
    puts "ActivityEntries to delete: #{entries_to_delete_count}"
    puts "ActivityEntries to keep: #{entries_to_keep_count} "

    if preview
      puts "Preview Mode, would have deleted #{entries_to_delete_count}"
    else
      puts "Deleting records..."
      entries_to_delete.in_batches(of: 200).delete_all
      puts "Done. Deleted #{entries_to_delete_count} ActivityEntry records"
    end
    puts "cleanup_activity_entries task completed."
  end
end
