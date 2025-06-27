module ResoTransport
  module Authentication
    class FetchTokenAuth < AuthStrategy
      attr_reader :endpoint, :client_id, :client_secret, :grant_type,
                  :scope, :username, :password, :audience, :json_token_fetch

      def initialize(options)
        super()

        @grant_type        = options.fetch(:grant_type, 'client_credentials')
        @scope             = options.fetch(:scope, 'api')
        @client_id         = options.fetch(:client_id)
        @client_secret     = options.fetch(:client_secret)
        @endpoint          = options.fetch(:endpoint)
        @username          = options.fetch(:username, nil)
        @password          = options.fetch(:password, nil)
        @audience          = options.fetch(:audience, nil)
        @json_token_fetch  = options.fetch(:json_token_fetch, false)
        @request           = nil
      end

      def connection
        @connection ||= Faraday.new(@endpoint) do |faraday|
          faraday.request :url_encoded unless json_token_fetch
          faraday.response :logger, ResoTransport.configuration.logger if ResoTransport.configuration.logger
          faraday.adapter Faraday.default_adapter
        end.tap do |conn|
          conn.basic_auth(client_id, client_secret)
        end
      end

      def authenticate
        if json_token_fetch
          response = connection.post do |req|
            req.headers['Content-Type'] = 'application/json'
            req.body = auth_params.to_json
            @request = req
          end
        else
          response = connection.post(nil, auth_params { |req| @request = req })
        end

        json = JSON.parse response.body

        raise AccessDenied.new(request, response, 'token') unless response.success?

        Access.new({
          access_token: json.fetch('access_token'),
          expires_in: json.fetch('expires_in', 1 << (1.size * 8 - 2) - 1),
          token_type: json.fetch('token_type', 'Bearer')
        })
      end

      def request
        return @request.to_h if @request.respond_to? :to_h
        {}
      end

      private

      def auth_params
        params = {
          client_id: client_id,
          client_secret: client_secret,
          grant_type: grant_type,
          scope: scope
        }

        params[:username] = username if grant_type == 'password'
        params[:password] = password if grant_type == 'password'
        params[:audience] = audience if audience

        params
      end
    end
  end
end