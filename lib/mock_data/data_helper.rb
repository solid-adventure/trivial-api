module MockData::DataHelper

  CUSTOMER_IDS = Array.new(200) { rand(1000..10000) }

  def self.entity_from_income_account(income_account)
    case income_account
    when 'items_1', 'items_2+', 'packaging'
      {
        name: 'order',
        id: rand(1..1000)
      }
    when 'carton'
      {
        name: 'asn',
        id: rand(1..1000)
      }
    when 'vas'
      {
        name: 'project',
        id: rand(1..1000)
      }
    else
      {
        name: '',
        id: ''
      }
    end

  end

  def self.customers
    [{
      id: 1000,
      name: 'Anthropologie'
    },
    {
      id: 1001,
      name: 'Urban Outfitters'
    },
    {
      id: 1002,
      name: 'Madewell'
    },
    {
      id: 1003,
      name: 'Athleta'
    },
    {
      id: 1004,
      name: 'Zara'
    }]
  end

  def self.warehouses
    [
      {
        id: 1,
        name: 'San Francisco'
      },
      {
        id: 2,
        name: 'New York'
      },
      {
        id: 3,
        name: 'Columbus'
      },
      {
        id: 4,
        name: 'Los Angeles'
      }
    ]
  end

  def self.item_count_from_income_account(income_account)
    case income_account
    when 'items_1', 'packaging'
      1
    when 'items_2+'
      rand(2..10)
    when 'carton'
      rand(1..100)
    else
      rand(1..10)
    end
  end

  def self.each_rate_from_income_account(income_account)
    case income_account
    when 'items_1'
      1.80
    when 'items_2+'
      0.75
    when 'packaging'
      [0.25, 0.65, 0.75].sample
    when 'carton'
      0.05
    when 'vas'
      18.25
    else
      1.0
    end
  end

  def self.income_account_group_from_income_account(income_account)
    case income_account
    when 'carrier_fees', 'items_1', 'items_2+', 'packaging'
      'outbound'
    when 'carton'
      'inbound'
    when 'storage'
      'storage'
    else
      'other'
    end
  end

  def self.amount_min
    0.1
  end

  def self.amount_max
    20.0
  end

  def self.locations
    return warehouses
  end

  def self.event_types
    entity_types
  end

  def self.event_actions
    %w[shipped received returned adjusted created deleted]
  end

  def self.income_accounts
    %w[items_1 items_2+ packaging vas carton]
  end

  def self.channels
    %w[d2c wholesale retail amazon etsy ebay]
  end

  def self.customer_ids
    CUSTOMER_IDS
  end

  def self.entity_types
    %w[shipment payment item return order asn]
  end

  def self.entity_id
    rand(1..1000000)
  end

  def self.status
    rand(25) == 1 ? 500 : 200
  end

  def self.generate_payload(event_type, event_action, event_id, customer_id, warehouse, originated_at)

    event_type ||= self.event_types.sample
    event_action ||= self.event_actions.sample
    event_id ||= self.entity_id
    customer_id ||= self.customer_ids.sample
    warehouse ||= self.warehouses.sample

    event_name = "#{event_type}.#{event_action}"
    key = "#{event_name}.#{customer_id}"

    string_keys = (1..20).each_with_object({}) do |i, hash|
      hash["string_key_#{i}".to_sym] = SecureRandom.alphanumeric(10)
    end

    numeric_keys = (1..10).each_with_object({}) do |i, hash|
      hash["numeric_key_#{i}".to_sym] = rand(1..1000000)
    end

    boolean_keys = (1..10).each_with_object({}) do |i, hash|
      hash["boolean_key_#{i}".to_sym] = [true, false, nil].sample
    end

    hash_keys = (1..5).each_with_object({}) do |i, hash|
      hash["hash_key_#{i}".to_sym] = generate_mock_hash
    end

    {
      key:,
      event_name:,
      event_type => {
        id: event_id,
        customer_id:,
        created_at: originated_at - 1.day,
        updated_at: originated_at,
        warehouse:,
        status: [200, 200, 300, 300, 400, 500, 600].sample,
        status_name: 'Mock Data',
        previous_status: [200, 200, 300, 300, 400, 500, 600].sample,
        **string_keys,
        **numeric_keys,
        **boolean_keys,
        **hash_keys,
        string_array_key_1: Array.new(rand(2..8)) { SecureRandom.alphanumeric(10) },
        string_array_key_2: Array.new(rand(2..8)) { SecureRandom.alphanumeric(10) },
        string_array_key_3: Array.new(rand(2..8)) { SecureRandom.alphanumeric(10) },
        numeric_array_key_1: Array.new(rand(2..8)) { rand(1..100000) },
        numeric_array_key_2: Array.new(rand(2..8)) { rand(1..100000) },
        numeric_array_key_3: Array.new(rand(2..8)) { rand(1..100000) },
        hash_array_key_1: Array.new(rand(2..8)) { generate_mock_hash },
        hash_array_key_2: Array.new(rand(2..8)) { generate_mock_hash },
        hash_array_key_3: Array.new(rand(2..8)) { generate_mock_hash }
      }
    }
  end

  def self.generate_mock_hash
    string_keys = (1..10).each_with_object({}) do |i, hash|
      hash["string_key_#{i}".to_sym] = SecureRandom.alphanumeric(10)
    end

    numeric_keys = (1..5).each_with_object({}) do |i, hash|
      hash["numeric_key_#{i}".to_sym] = rand(1..1000000)
    end

    boolean_keys = (1..5).each_with_object({}) do |i, hash|
      hash["boolean_key_#{i}".to_sym] = [true, false, nil].sample
    end

    {
      **string_keys,
      **numeric_keys,
      **boolean_keys,
      string_array_key_1: Array.new(rand(2..8)) { SecureRandom.alphanumeric(10) },
      numeric_array_key_1: Array.new(rand(2..8)) { rand(1..100000) }
    }
  end
end