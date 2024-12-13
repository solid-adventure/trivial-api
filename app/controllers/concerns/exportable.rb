# app/controllers/concerns/exportable.rb
require 'csv'

module Exportable
  extend ActiveSupport::Concern

  included do
    before_action :verify_export_serializer, only: %i[index]
  end

  class_methods do
    attr_accessor :export_serializer
  end

  private
    MAX_CSV_ROWS = 500_000
    def handle_csv_export(collection:)
      if collection.size > MAX_CSV_ROWS
        render json: {
          error: "CSV row limit exceeded",
          message: "Limit is #{ MAX_CSV_ROWS }, requested #{ collection.size } rows. "
        }, status: :bad_request
        return
      end
      set_headers(collection:)
      stream_csv(collection:)
    end

    def verify_export_serializer
      if params[:format] == 'csv'
        raise 'Invalid export serializer' unless self.class.export_serializer
      end
    end

    def set_headers(collection:)
      headers.merge!(
        'Content-Type' => 'text/csv; charset=utf-8',
        'Content-Disposition' => "attachment; filename=\"#{controller_name}-#{Date.today}.csv\"",
        'X-Items-Count' => collection.size,
        'Last-Modified' => Time.now.httpdate
      )
    end

    def stream_csv(collection:)
      self.response_body = Enumerator.new do |yielder|
        # stream the csv headers based on serializer attributes
        serializer = self.class.export_serializer.new(collection.first)
        csv_headers = serializer.serializable_hash.keys
        yielder << CSV.generate_line(csv_headers)

        # stream the collection in batches
        batch_size = params[:batch_size] ? params[:batch_size].to_i : 1000
        collection.find_in_batches(batch_size:) do |batch|
          # serialize the current batch
          serialized_batch = ActiveModel::Serializer::CollectionSerializer.new(
            batch,
            serializer: self.class.export_serializer
          ).as_json

          # stream the serialized rows
          serialized_batch.each do |row|
            yielder << CSV.generate_line(row.values)
          end
        end
      end
    end
end
