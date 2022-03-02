module ResoTransport
  module Authentication
    class FetchTokenAuth < AuthStrategy
      attr_reader :endpoint,
                  :client_id,
                  :client_secret,
                  :grant_type,
                  :scope,
                  :username,
                  :password

      def initialize(options)
        super()

        @grant_type    = options.fetch(:grant_type, 'client_credentials')
        @scope         = options.fetch(:scope, 'api')
        @client_id     = options.fetch(:client_id)
        @client_secret = options.fetch(:client_secret)
        @endpoint      = options.fetch(:endpoint)
        @username      = options.fetch(:username, nil)
        @password      = options.fetch(:password, nil)
        @request       = nil
      end

      def connection
        @connection ||= Faraday.new(@endpoint) do |faraday|
          faraday.request  :url_encoded
          faraday.response :logger, ResoTransport.configuration.logger if ResoTransport.configuration.logger
          faraday.adapter Faraday.default_adapter
          faraday.basic_auth client_id, client_secret
        end
      end

      def authenticate
        response = connection.post(nil, auth_params { |req| @request = req })
        json = JSON.parse response.body

        raise AccessDenied.new(@request, response, 'token') unless response.success?

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

        if grant_type == 'password'
          params[:username] = username
          params[:password] = password
        end

        params
      end
    end
  end
end
