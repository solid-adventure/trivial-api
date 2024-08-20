namespace :tasks do
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
    raise 'must supply number of days to keep' unless args[:days_kept]
    cutoff_date = Time.now - args[:days_kept].to_i.days
    puts "Preparing to remove outdated ActivityEntries, current cutoff date is #{cutoff_date}."

    preview = ActiveModel::Type::Boolean.new.cast(args[:preview])
    preview = true if preview.nil?

    entries_to_delete = ActivityEntry.where(register_item_id: nil)
                                     .where('created_at < ?', cutoff_date)
    puts "#{entries_to_delete.count} ActivityEntries to delete."

    if preview
      puts "Preview Mode, would have deleted #{entries_to_delete.count}"
    else
      deleted_count = entries_to_delete.destroy_all.length
      puts "Deleted #{deleted_count} ActivityEntry records"
    end
  end
end
