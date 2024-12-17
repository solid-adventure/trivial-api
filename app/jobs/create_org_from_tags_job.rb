# app/jobs/create_orgs_from_tags_job.rb
class CreateOrgsFromTagsJob < ApplicationJob
  queue_as :default

  def perform(options: {})
    contract_customer_tags = Tags.where(context: 'customer_id', taggable_type: 'App')
    organization_customer_tags = Tags.where(context: 'customer_id', taggable_type: 'Organization')
    customer_ids = contract_customer_tags.where.not(name: organization_customer_tags.pluck(:name)).pluck(:name)
    customer_ids.each do |customer_id|
      Organization.create_by_customer_id(customer_id)
    end
  end
end
