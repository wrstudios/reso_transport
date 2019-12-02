module ResoTransport
  module Authentication
    # A simple auth strategy that uses a static, non-expiring token.
    class StaticTokenAuth < AuthStrategy
      attr_reader :access_token
      attr_reader :token_type

      def initialize(options)
        @access_token = options.fetch(:access_token)
        @token_type   = options.fetch(:token_type, "Bearer")
      end

      # Simply returns a static, never expiring access token
      # @return [Access] The access token object
      def authenticate
        Access.new(
          access_token: access_token,
          token_type: token_type,
          expires_in: 1 << (1.size * 8 - 2) - 1 # Max int value
        )
      end
    end
  end
end
