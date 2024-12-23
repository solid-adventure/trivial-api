class RerunActivityJob < ApplicationJob
  queue_as :default

  def perform(options)
    service = Services::ActivityRerun.new(**options)
    service.call
  end
end