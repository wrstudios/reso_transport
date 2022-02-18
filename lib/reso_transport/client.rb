module ResoTransport
  class Client
    attr_reader :connection, :uid, :vendor, :endpoint, :authentication, :md_file, :md_cache, :ds_file, :ds_cache,
                :use_replication_endpoint

    def initialize(options)
      @use_replication_endpoint = options.fetch(:use_replication_endpoint, false)
      @endpoint                 = options.fetch(:endpoint)
      @md_file                  = options.fetch(:md_file, nil)
      @ds_file                  = options.fetch(:ds_file, nil)
      @authentication           = ensure_valid_auth_strategy(options.fetch(:authentication))
      @vendor                   = options.fetch(:vendor, {})
      @faraday_options          = options.fetch(:faraday_options, {})
      @logger                   = options.fetch(:logger, nil)
      @md_cache                 = options.fetch(:md_cache, ResoTransport::MetadataCache)
      @ds_cache                 = options.fetch(:ds_cache, ResoTransport::MetadataCache)
      @connection               = establish_connection
    end

    def establish_connection
      Faraday.new(@endpoint, @faraday_options) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger, @logger || ResoTransport.configuration.logger
        faraday.use Authentication::Middleware, @authentication
        faraday.adapter Faraday.default_adapter # unless faraday.builder.send(:adapter_set?)
      end
    end

    def resources
      @resources ||= metadata.entity_sets.map { |es| { es.name => resource_for(es) } }.reduce(:merge!)
    end

    def resource_for(entity_set)
      localizations = {}
      localizations = datasystem.localizations_for(entity_set.entity_type) if metadata.datasystem?

      Resource.new(self, entity_set, localizations)
    end

    def metadata
      @metadata ||= Metadata.new(self)
    end

    def datasystem
      @datasystem ||= Datasystem.new(self)
    end

    def fetch(url)
      connection.get(url)
    end

    def to_s
      %(#<ResoTransport::Client endpoint="#{endpoint}", md_file="#{md_file}", ds_file="#{ds_file}">)
    end

    def inspect
      to_s
    end

    private

    def ensure_valid_auth_strategy(options)
      case options
      when Hash
        if options.key?(:endpoint)
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
