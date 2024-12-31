# app/jobs/create_orgs_from_tags_job.rb
class CreateOrgsFromTagsJob < ApplicationJob
  queue_as :default

  def perform(options: {})
    contract_tags = Tag.where(context: 'customer_id', taggable_type: 'App')
    organization_tags = Tag.where(context: 'customer_id', taggable_type: 'Organization')
    customer_ids = contract_tags.where.not(name: organization_tags.pluck(:name)).pluck(:name).uniq

    get_name_proc = if options[:integration] && Integrations.const_defined?(options[:integration])
                      integration = Integrations.const_get(options[:integration]).new
                      ->(id) { integration.get_customer_name_by_id(id) }
                    else
                      nil
                    end
    customer_ids.each do |customer_id|
      Organization.create_by_customer_id(customer_id, get_name_proc:)
    end
  end
end
