require 'test_helper'

class KafkaTest < ActiveSupport::TestCase

  def setup
    @kafka = Services::Kafka.new
  end

  test 'initializes' do
    assert_instance_of WaterDrop::Producer, @kafka.producer
  end

  test 'throws when topic is not set' do
    mock_enviroment(partial_env_hash:{"KAFKA_TOPIC"=>"", "KAFKA_NAMESPACE" => ""}) do
      assert_raises RuntimeError do
        Services::Kafka.topic
      end
    end
  end

  test 'derives topic from env var' do
    mock_enviroment(partial_env_hash:{"KAFKA_TOPIC"=>"events"}) do
      assert_equal "events", Services::Kafka.topic
    end
  end

  test 'appends runtime topic' do
    mock_enviroment(partial_env_hash:{"KAFKA_TOPIC" => "events", "KAFKA_NAMESPACE" => "SUP"}) do
      assert_equal "SUP-events", Services::Kafka.topic
      assert_equal "SUP-events-suffix", Services::Kafka.topic('suffix')
    end

    mock_enviroment(partial_env_hash:{"KAFKA_TOPIC" => "", "KAFKA_NAMESPACE" => ""}) do
      assert_equal "suffix", Services::Kafka.topic('suffix')
    end
  end


  test 'throws when payload is nil' do
    assert_raises TypeError do
      @kafka.produce_sync(topic: "events", payload: nil, key: "key")
    end
  end

  test 'does not throw when payload is valid' do
    assert_nothing_raised do
      @kafka.validate_payload({key: "value"}.to_json)
    end
  end


end

