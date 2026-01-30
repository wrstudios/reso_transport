module ResoTransport
  module Authentication
    class FetchTokenAuth < AuthStrategy
      attr_reader :endpoint, :client_id, :client_secret, :grant_type,
                  :scope, :username, :password, :audience,
                  :json_token_fetch, :use_basic_auth

      def initialize(options)
        super()

        @endpoint         = options.fetch(:endpoint) # FULL token URL

        @grant_type       = options.fetch(:grant_type, "client_credentials")
        @scope            = options.fetch(:scope, nil)

        @client_id        = options.fetch(:client_id)
        @client_secret    = options.fetch(:client_secret)

        @username         = options.fetch(:username, nil)
        @password         = options.fetch(:password, nil)
        @audience         = options.fetch(:audience, nil)

        @json_token_fetch = options.fetch(:json_token_fetch, false)

        # Backward compatible: most adapters historically worked with Basic Auth enabled.
        # You can override per adapter (e.g. HIIS: false).
        @use_basic_auth   = options.fetch(:use_basic_auth, true)

        @request          = nil
      end

      def connection
        @connection ||= Faraday.new(base_url) do |faraday|
          faraday.request :url_encoded unless json_token_fetch
          faraday.response :logger, ResoTransport.configuration.logger if ResoTransport.configuration.logger
          faraday.adapter Faraday.default_adapter
        end.tap do |conn|
          conn.basic_auth(client_id, client_secret) if use_basic_auth
        end
      end

      def authenticate
        response =
          if json_token_fetch
            connection.post(token_path_with_query) do |req|
              req.headers["Content-Type"] = "application/json"
              req.body = auth_params.to_json
              @request = req
            end
          else
            connection.post(token_path_with_query, auth_params) do |req|
              @request = req
            end
          end

        raise AccessDenied.new(request, response, "token") unless response.success?

        json = JSON.parse(response.body)

        Access.new(
          access_token: json.fetch("access_token"),
          expires_in: json.fetch("expires_in", 1 << (1.size * 8 - 2) - 1),
          token_type: json.fetch("token_type", "Bearer")
        )
      end

      def request
        return @request.to_h if @request.respond_to?(:to_h)
        {}
      end

      private

      def uri
        @uri ||= URI(endpoint)
      end

      def base_url
        "#{uri.scheme}://#{uri.host}"
      end

      def token_path_with_query
        path = uri.path
        path = "/" if path.nil? || path.empty?
        uri.query ? "#{path}?#{uri.query}" : path
      end

      # Always include client credentials in the request body for backward compatibility.
      # Some providers (e.g., Realcomp) require body creds even if Basic Auth is present.
      def auth_params
        params = {
          grant_type: grant_type,
          client_id: client_id,
          client_secret: client_secret
        }

        # omit blank scope ("" is common in our configs)
        params[:scope] = scope if scope && !scope.to_s.empty?

        if grant_type == "password"
          params[:username] = username
          params[:password] = password
        end

        params[:audience] = audience if audience

        params
      end
    end
  end
end