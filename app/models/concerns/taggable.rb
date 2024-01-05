module Taggable
  extend ActiveSupport::Concern

  included do
    def addTag!(context, tag)
      begin
        self.tags.create(context: context, name: tag)
      rescue TagExists => e
        self.tags.where(context: context, name: tag).first
      end
    end

    def removeTag!(context, tag)
      self.tags.where(context: context, name: tag).delete_all
    end

    def copyTagsTo(new_taggable)
      self.tags.each do |tag|
        new_taggable.addTag!(tag.context, tag.name)
      end
    end
  end

  class_methods do

    # App.find_by_all_tags([{'currency': 'USD'}, {'customer_ids': '1'}])
    def find_by_all_tags(tag_list)
      self.joins(joins_for_tags(tag_list)).where(where_for_tags(tag_list).join(" AND "))
    end

    def joins_for_tags(tag_list)
      joins = []
      tag_list.each do |item|
        table_alias = table_alias_for_tag(item)
        joins << <<~SQL
          LEFT OUTER JOIN "tags" #{table_alias}
          ON "#{table_alias}"."taggable_type" = 'App'
          AND "#{table_alias}"."taggable_id" = "apps"."id"
          AND "#{table_alias}"."context" = '#{item.keys.first}'
        SQL
      end

      return joins
    end

    def where_for_tags(tag_list)
      where = []
      tag_list.each do |item|
        table_alias = table_alias_for_tag(item)
        where << "\"#{table_alias}\".\"name\" = '#{item.values.first}'"
      end
      return where
    end

    def table_alias_for_tag(tag)
      "#{tag.keys.first}_tags"
    end

  end

end
