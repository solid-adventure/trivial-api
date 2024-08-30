#
#
# WARNING: This script will create a large number of records in your database.
#
#          DO NOT run this script on a production database.
#
#

# You must provide a valid app_id to run this script.
# You can also provide the following optional arguments:
# - row_count: the number of register items to create (default: 1000)
# - group_size: the number of register items to insert in a single query (default: 8000)
# - entries_per_item: the number of activity entries to create for each register item (default: 20)
# - start_at: the start date for the register items (default: 2016-01-02)
# - end_at: the end date for the register items (default: now)
#
# Example:
# MockData::RegisterItems.main({app_id: 100, row_count: 10, group_size: 20, entries_per_item: 2})

# Example With dates provided:
# MockData::RegisterItems.main({app_id: 100, row_count: 10, group_size: 20, entries_per_item: 2, start_at: '2025-01-01', end_at: '2025-01-10'})


module MockData::RegisterItems
  include MockData::DataHelper

  def self.main (args = {})
    @perf_start = Time.now
    puts "Creating mock register items..."
    init_defaults(args)
    insert_register_items
    @perf_end = Time.now
    puts "Inserted #{@insertion_count} of #{@row_count} items in #{@perf_end - @perf_start} seconds"
    puts "Completed mock register items creation"
  end

  def self.init_defaults(args)
    raise "app_id is required" if args[:app_id].nil?
    @run_id = rand(1000000)
    @app = App.find(args[:app_id])
    @owner = @app.owner
    @start_date = args[:start_at] ? Time.parse(args[:start_at]) : Time.new(2016,01,02)
    @end_date = args[:end_at] ? Time.parse(args[:end_at]) : Time.now
    raise "end date must be after start date" if @end_date < @start_date
    @row_count = args[:row_count] ? args[:row_count].to_i : 1000
    @group_size = args[:group_size] ? args[:group_size].to_i : 8000
    @insertion_count = 0
    @entry_insertion_count = 0
    @entries_per_register_item = args[:entries_per_item] ? args[:entries_per_item].to_i : 20
    set_register

    puts "start_date: #{@start_date}, end_date: #{@end_date}, row_count: #{@row_count}, run_id: #{@run_id}, group_size: #{@group_size}"
  end

  def self.set_register
    puts "Setting register..."
    @register = Register.find_or_create_by!(
      name: "Sales",
      sample_type: "increment",
      units: "USD",
      owner_type: @owner.class.to_s,
      owner_id: @owner.id
    )
    @register.meta = {
        meta0: "customer_id",
        meta1: "income_account",
        meta2: "entity_type",
        meta3: "entity_id",
        meta4: "warehouse",
    }
    @register.save
  end

  def self.insert_register_items
    puts "Inserting register items..."
    @group_count = (@row_count.to_f / @group_size).ceil
    @group_count.times do |g|
      register_items = []
      puts "Inserting register item group #{g+1} of #{@group_count}"
      @group_size.times do |i|
        break if @insertion_count >= @row_count
        @insertion_count += 1
        register_items << generate_register_item
      end
      register_item_ids = RegisterItem.insert_all!(register_items).map { |r| r['id'] }.each
      insert_activity_entries(register_item_ids)
    end
  end

  def self.generate_register_item
    originated_at = rand(@start_date..@end_date)
    {
      register_id: @register.id,
      owner_type: @register.owner_type,
      owner_id: @register.owner_id,
      description: "Generated event, run #{@run_id}: #{@insertion_count}",
      amount: rand(MockData::DataHelper.amount_min..MockData::DataHelper.amount_max).round(2),
      units: "USD",
      unique_key: "#{Time.now}-#{@insertion_count}",
      created_at: originated_at + 1.day,
      originated_at: originated_at,
      meta0: MockData::DataHelper.customer_ids.sample,
      meta1: MockData::DataHelper.income_accounts.sample,
      meta2: MockData::DataHelper.entity_types.sample,
      meta3: @insertion_count,
      meta4: MockData::DataHelper.warehouses.sample
    }
  end

  def self.insert_activity_entries(register_item_ids=[])
    puts "Inserting activity entries..."
    entry_row_count = register_item_ids.size * @entries_per_register_item
    entry_group_count = (entry_row_count.to_f / @group_size).ceil
    puts "Inserting #{entry_row_count} activity entries in #{entry_group_count} groups"
    register_item_ids_enum = register_item_ids.to_enum
    entry_group_count.times do |g|
      activity_entries = []
      puts "Inserting entry group #{g+1} of #{entry_group_count}"
       @group_size.times do |i|
        break if @entry_insertion_count >= entry_row_count
        register_item_id = next_id_or_null(register_item_ids_enum)
        activity_entries << generate_activity_entry(register_item_id)
        @entry_insertion_count += 1
      end
      ActivityEntry.insert_all!(activity_entries) if activity_entries.any?
    end

  end

  def self.next_id_or_null(enum)
    if rand(@entries_per_register_item) == 0  # 1 in N chance we'll grab the next ID off the list
      begin
        enum.next
      rescue StopIteration
        nil
      end
    else
      nil
    end
  end

  def self.generate_activity_entry(register_item_id)
    originated_at = rand(@start_date..@end_date)
    {
      app_id: @app.id,
      update_id: SecureRandom.uuid,
      activity_type: 'mock event',
      status: MockData::DataHelper.status,
      source: "Mock Data run #{@run_id}",
      duration_ms: rand(100..5000),
      payload: MockData::DataHelper.generate_payload(nil, nil, nil, nil, nil, originated_at),
      diagnostics: { events: [], errors: [] },
      owner_type: @owner.class,
      owner_id: @owner.id,
      register_item_id: register_item_id
    }
  end

end