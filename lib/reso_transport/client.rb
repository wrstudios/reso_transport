module ResoTransport
  class Client
    attr_reader :connection, :uid, :vendor, :endpoint, :auth, :md_file, :md_cache, :use_replication_endpoint

    def initialize(options)
      @use_replication_endpoint = options.fetch(:use_replication_endpoint, false)
      @endpoint                 = options.fetch(:endpoint)
      @md_file                  = options.fetch(:md_file, nil)
      @authentication           = ensure_valid_auth_strategy(options.fetch(:authentication))
      @vendor                   = options.fetch(:vendor, {})
      @faraday_options          = options.fetch(:faraday_options, {})
      @logger                   = options.fetch(:logger, nil)
      @md_cache                 = options.fetch(:md_cache, ResoTransport::MetadataCache)

      @connection = Faraday.new(@endpoint, @faraday_options) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger, @logger || ResoTransport.configuration.logger
        #yield faraday if block_given?
        faraday.use Authentication::Middleware, @authentication
        faraday.adapter Faraday.default_adapter #unless faraday.builder.send(:adapter_set?)
      end
    end

    def resources
      @resources ||= metadata.entity_sets.map {|es| {es.name => Resource.new(self, es)} }.reduce(:merge!)
    end

    def metadata
      @metadata ||= Metadata.new(self)
    end

    def to_s
      %(#<ResoTransport::Client endpoint="#{endpoint}", md_file="#{md_file}">)
    end

    def inspect
      to_s
    end

    private

    def ensure_valid_auth_strategy(options)
      case options
      when Hash
        if options.has_key?(:endpoint)
          Authentication::FetchTokenAuth.new(options)
        else
          Authentication::StaticTokenAuth.new(options)
        end
      else
        raise ArgumentError, "#{options.inspect} invalid:  cannot determine strategy"
      end
    end

  end
end
