module ResoTransport
  module Authentication
    # Authentication middleware
    # Ensures that each request is made with proper `Authorization` header set
    # and raises an exception if a request yields a `401 Access Denied` response.
    class Middleware < Faraday::Middleware
      AUTH_HEADER = 'Authorization'.freeze

      def initialize(app, auth)
        super(app)
        @auth = auth
      end

      def call(request_env)
        retries = 1

        begin
          authorize_request(request_env)

          @app.call(request_env).on_complete do |response_env|
            raise_if_unauthorized(request_env, response_env)
          end
        rescue ResoTransport::AccessDenied
          raise if retries.zero?

          @auth.reset
          retries -= 1
          retry
        end
      end

      private

      def authorize_request(request_env)
        @auth.ensure_valid_access!

        request_env[:request_headers].merge!(
          AUTH_HEADER => "#{@auth.access.token_type} #{@auth.access.access_token}"
        )
      end

      def raise_if_unauthorized(request_env, response_env)
        raise ResoTransport::AccessDenied.new(request_env.to_h, response_env) if response_env[:status] == 401
      end
    end
  end
end
