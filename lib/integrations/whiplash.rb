module Integrations
  class Whiplash

    def getCustomersById(ids='')
      fields = 'id,name'
      search = {
        id_in: ids.split(',').map(&:to_i),
        quote_eq: false
      }
      api.get("/api/v2/customers?fields=#{fields}&search=#{search.to_json}").body
    end

    def getCustomersByName(name='')
      limit = 5
      fields = 'id,name'
      search = {
        name_cont: name,
        quote_eq: false
      }
      api.get("/api/v2/customers?fields=#{fields}&per_page=#{limit}&search=#{search.to_json}").body
    end


    private

    def token
      @token ||= get_token
    end

    def whiplash_url
      ENV['WHIPLASH_BASE_URL']
    end

    def api
      Faraday.new(url: whiplash_url)  do |builder|
        builder.request :authorization, 'Bearer', -> { token }
        builder.request :json
        builder.response :json
        builder.response :raise_error
        # builder.response :logger
      end
    end

    def get_token
      conn = Faraday.new(url: whiplash_url)  do |builder|
        builder.request :json
        builder.response :json
        builder.response :raise_error
        # builder.response :logger
      end

      conn.post('/oauth/token', {
          scope: 'app_manage',
          client_id: ENV['WHIPLASH_CLIENT_ID'],
          client_secret: ENV['WHIPLASH_CLIENT_SECRET'],
          grant_type: 'client_credentials'
        }
      ).body['access_token']
    end

  end
end
