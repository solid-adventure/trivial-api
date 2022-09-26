namespace :tasks do

  # rake tasks:run_scheduled_every_10_minutes
  desc "Run apps scheduled for every 10 minutes"
  task run_scheduled_every_10_minutes: :environment do
    puts "Starting Scheduled Every 10 Minutes apps..."
    apps = App.kept.where('schedule @> ?', '{"every": "10 minutes"}')
    apps.each do |app|
      puts "Running #{app.name}, #{app.descriptive_name}"
      begin 
        res = ActivityEntry.send_new app, app.schedule["payload"]
        puts res
      rescue => e
        puts "Error running #{app.name}, #{app.descriptive_name}: #{e}"
      end
      puts "Completed #{app.name}, #{app.descriptive_name}"
    end
    puts "Completed Scheduled Every 10 Minutes apps."
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

  desc "Create Sign Up events in PostHog for existing users"
  task backfill_user_signups: :environment do

    posthog = PostHog::Client.new({
      api_key: ENV['POSTHOG_API_KEY'],
      api_host: ENV['POSTHOG_HOST'],
      on_error: Proc.new { |status, msg| print msg }
    })

    User.where("created_at > ?", Time.now - 7.day).each do |user|
      puts posthog.capture({
        distinct_id: user.email,
        event: 'User Signup',
        properties: {
            source: 'backfill_user_signups',
        },
        timestamp: user.created_at
      })
    end
  end

end
