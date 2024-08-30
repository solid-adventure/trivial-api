module MockData::DataHelper

  CUSTOMER_IDS = Array.new(200) { rand(1000..10000) }


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
    %w[postage handling storage packaging vas]
  end

  def self.warehouses
    %w[san\ francisco ann\ arbor detroit minneapolis new\ york atlanta little\ rock london tokyo paris]
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