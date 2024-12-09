require 'csv'

class StreamController < ApplicationController
  include ActionController::Live
  before_action :load_cache_data
  before_action :set_headers
  skip_after_action :update_auth_header

  def csv
    serializer = @serializer_class.new(@relation.first)
    csv_headers = serializer.serializable_hash.keys
    response.stream.write CSV.generate_line(csv_headers)

    @relation.find_in_batches(batch_size: 1000) do |batch|
      serialized_batch = ActiveModel::Serializer::CollectionSerializer.new(batch, serializer: @serializer_class).as_json
      serialized_batch.each do |row|
        response.stream.write CSV.generate_line(row.values)
      end
    end
  rescue ActionController::Live::ClientDisconnected => e
    Rails.logger.info "Client disconnected: #{e.message}"
  ensure
    response.stream.close
  end

  private
    def load_cache_data
      token = params[:token]
      cache_data = Rails.cache.read(token)
      Rails.cache.delete(token)

      raise CanCan::AccessDenied if cache_data.nil?

      @model_class = cache_data[:model]
      @serializer_class = cache_data[:serializer]

      sql = cache_data[:sql]
      @relation = @model_class.from("(#{sql}) AS #{@model_class.table_name}")
    end

    def set_headers
      response.headers['Content-Type'] = 'text/csv'
      response.headers['Content-Disposition'] = "attachment; filename=#{@model_class.table_name}-#{Date.today}.csv"
      response.headers['X-Items-Count'] = @relation.size
      response.headers['Last-Modified'] = Time.now.httpdate
    end
end
