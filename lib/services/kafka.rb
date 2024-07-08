module Services
  class Kafka

    def initialize
      @producer = WaterDrop::Producer.new do |config|
        config.deliver = true
        config.kafka = {
          'bootstrap.servers': ENV['KAFKA_BOOTSTRAP_SERVERS'],
          'sasl.username': ENV['KAFKA_USERNAME'],
          'sasl.password': ENV['KAFKA_PASSWORD'],
          'security.protocol': 'SASL_SSL',
          'sasl.mechanisms': 'PLAIN',
          'request.required.acks': 1
        }
      end
    end

    def producer
      @producer
    end

    def produce_async(topic:, payload:, key:)
      validate_payload(payload)
      producer.produce_async(topic: topic, payload: payload, key: key)
    end

    def produce_sync(topic:, payload:, key:)
      validate_payload(payload)
      producer.produce_sync(topic: topic, payload: payload, key: key)
    end

    def validate_payload(payload=nil)
      payload = JSON.parse(payload)
      raise "Invalid payload, JSON invalid" unless payload.is_a?(Hash)
      raise "Invalid payload, key not defined" unless payload["key"]
    end

    def self.topic(topic=nil)
      parts = [ENV['KAFKA_NAMESPACE'], ENV['KAFKA_TOPIC'], topic].compact.reject(&:empty?)
      raise "Invalid topic" if parts.empty?
      parts.join('-')
    end

  end
end