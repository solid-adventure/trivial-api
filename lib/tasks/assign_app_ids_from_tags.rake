# Usage: rake assign_app_ids_from_tags:run

namespace :assign_app_ids_from_tags do
  desc "Attaches app IDs to register_items based on app tags"
  task run: :environment do
    begin

      # There is a convention prior to now that is being made official. Currently, a contract is tagged with a customer_id, that
      # contract is used to create register items, and the register items contain the customer_id. This makes the link
      # between the register item the contract that produced it explicit, making it easier to predictably re-run all events produced by a contract.
      # If there are mutiple app tags assigned to the same customer, the most recently created will take precedence.

      # 1. Get apps with tags and fish out the customer_id so we have a list of app_id: customer_id
      customer_tags = Tag.where(taggable_type: "App", context: "customer_id")
      customer_app_ids = customer_tags.collect do |tag| {app_id: tag.taggable_id, customer_id: tag.name } end
      # => [{:app_id=>53, :customer_id=>"194"}, {:app_id=>53, :customer_id=>"2789"}]


      # 2. Find the meta column for the customer_id for each register
      Register.all.each do |register|
        customer_id_meta = register.meta.find { |k,v,| v == 'customer_id' }
        #  => ["meta0", "customer_id"]
        if !customer_id_meta || customer_id_meta.length == 0
          puts "No customer_id meta column, skipping register #{register.name}"
          next
        end
        customer_id_meta = customer_id_meta[0]

        # 3. Iterate through our list of app_id: customer_id and update the meta column in the register items
        customer_app_ids.each do |app|
          puts "Assigning app_id: #{app[:app_id]} to customer_id: #{app[:customer_id]}"
          count = RegisterItem
            .where(register_id: register.id)
            .where("#{customer_id_meta} = ?", app[:customer_id])
            .update_all(app_id: app[:app_id])
          puts "Updated #{count} register items for app_id: #{app[:app_id]}"
        end
      end

      puts 'App Ids attaching completed successfully'
    rescue => e
      puts "App Ids attaching failed: #{e.message}"
      raise e
    end
  end
end