namespace :tasks do

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

# To create 1000 transactions in the last 24 hours:
# rake "tasks:mock_register_items[58, 1000, 1, 0]"

# To create 2000 transactions in the last week:
# rake "tasks:mock_register_items[58, 1000, 7, 0]"

# To create 500 transactions in a roughly month, rougly one month ago:
# rake "tasks:mock_register_items[58, 1000, 60, 30]"
  desc "Create mock register item data for date range - non-production only"
  task :mock_register_items, [:register_id, :row_count, :offset_start_in_days, :offset_end_in_days] => :environment do |t, args|
    puts "Creating mock register items..."
    raise "Mock items cannot be created in production" if Rails.env.production?
    raise "register_id is required" if args[:register_id].nil?

    register = Register.find(args[:register_id])
    row_count = args[:row_count] ? args[:row_count].to_i : 1000

    offset_start_in_days = args[:offset_start_in_days] ? args[:offset_start_in_days].to_i : 1
    offset_end_in_days = args[:offset_end_in_days] ? args[:offset_end_in_days].to_i : 0

    start_date = Time.now - offset_start_in_days.days
    end_date = Time.now - offset_end_in_days.days

    puts "start_date: #{start_date}, row_count: #{row_count}, end_date: #{end_date}, register_id: #{args[:register_id]}"

    perf_start = Time.now
    insertion_count = 0
    items = []
    group_size = 8000
    group_count = (row_count.to_f / group_size).ceil
    group_count.times do |g|
      items = []
      group_size.times do |i|
        insertion_count+=1
        next if insertion_count > row_count
        items << {
          register_id: register.id,
          owner_type: register.owner_type,
          owner_id: register.owner_id,
          description: "Generated event #{(i+1) * (g+1)}",
          amount: rand(0.1..20.0).round(2),
          units: "USD",
          unique_key: "#{Time.now}-#{g}#{i}",
          originated_at: rand(start_date..end_date),
          meta0: [7457, 3929, 8728].sample,
          meta1: ["VAS", "shipping", "receiving", "carrier_fees", "storage", "shipping"].sample,
          meta2: ["shipment","chargeback","adjustment","payment","item","return","refund","order"].sample,
          meta3: [134889, 627673, 904842, 915999,323638].sample,
          meta4: ["Tokyo", "Paris", "London", "New York", "Los Angeles", "San Francisco"].sample,
          # meta0: ["san_francisco", "los_angeles", "new_york", "paris", "london", "tokyo"].sample,
          # meta1: ["carrier_fees", "storage", "receiving", "shipping", "VAS"].sample
        }
        # puts "Creating group #{g}, item #{i}, insertion_count: #{insertion_count}"
      end
      RegisterItem.insert_all! items
      puts "Inserted group #{g+1} of #{group_count} with #{items.size} items."
    end
    perf_end = Time.now
    puts "Time to insert #{row_count} items: #{perf_end - perf_start} seconds"

    puts "Completed mock register items creation"

  end

end
