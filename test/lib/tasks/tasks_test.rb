require 'test_helper'
require 'rake'

class RakeTaskTest < ActiveSupport::TestCase

  def setup
    # See https://karafka.io/docs/WaterDrop-Testing/#buffered-client
    @producer = KAFKA.producer
    @producer.config.client_class = WaterDrop::Clients::Buffered
    @producer.client.reset
  end

  test 'kafka mock initializes' do
    handle = @producer.produce_async(topic: 'test', payload: '123')
    assert_equal @producer.client.messages.last, {:topic=>"test", :payload=>"123"}
  end

  test 'sends new period started events' do
      # Load rake tasks if they aren't already
      Api::Application.load_tasks if Rake::Task.tasks.empty?

      # Confirm our starting conditions
      assert_equal @producer.client.messages.count, 0
      assert_equal Tag.where(taggable_type: "App", context: "customer_id").pluck(:name), ["1","2"]

      # Run the rake task and ensure the producer now has the two messages the task should have created
      Rake::Task["tasks:send_new_period_started_events"].invoke
      assert_equal @producer.client.messages.count, 2

      payloads = @producer.client.messages.map {|m| JSON.parse m[:payload] }
      assert_equal  payloads.map { |p| p["name"] }.uniq, ["New Period Started"]
  end

end

