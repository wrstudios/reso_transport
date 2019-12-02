module ResoTransport
  module Authentication
    class FetchTokenAuth < AuthStrategy
      attr_reader :connection, :endpoint, :client_id, :client_secret, :grant_type, :scope
      
      def initialize(options)
        @grant_type    = options.fetch(:grant_type, "client_credentials")
        @scope         = options.fetch(:scope, "api")
        @client_id     = options.fetch(:client_id)
        @client_secret = options.fetch(:client_secret)
        @endpoint      = options.fetch(:endpoint)

        @connection = Faraday.new(@endpoint) do |faraday|
          faraday.request  :url_encoded
          faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.basic_auth @client_id, @client_secret
        end
      end

      def authenticate
        response = connection.post nil, auth_params
        json = JSON.parse response.body

        unless response.success?
          message = "#{response.reason_phrase}: #{json['error'] || response.body}"
          raise ResoTransport::AccessDenied, response: response, message: message
        end

        Access.new({
          access_token: json.fetch('access_token'),
          expires_in: json.fetch('expires_in', 1 << (1.size * 8 - 2) - 1),
          token_type: json.fetch('token_type', "Bearer")
        })
      end

      private

      def auth_params
        {
          client_id:     client_id,
          client_secret: client_secret,
          grant_type:    grant_type,
          scope:         scope
        }
      end
    end
  end
end
