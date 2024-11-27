# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.filtered_attributes
    filter_strings = filter_attributes.map { |filter| Regexp.escape(filter.to_s) }
    filter_regex = Regexp.new(filter_strings.join("|"), true)
    column_names.map do |column_name|
      column_name.to_sym if filter_regex.match?(column_name)
    end.compact
  end
end
