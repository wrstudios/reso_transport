require_relative 'base_metadata'

module ResoTransport
  class Metadata < BaseMetadata
    def initialize(client)
      super client
      @prefix = 'md'
      @classname = self.class.name
    end

    def entity_sets
      parser.entity_sets
    end

    def schemas
      parser.schemas
    end

    def datasystem?
      parser.datasystem?
    end

    def response
      @response ||= client.connection.get('$metadata') do |req|
        req.headers['Accept'] = MIME_TYPES[client.vendor.fetch(:metadata_format, :xml).to_sym]
      end
    rescue Faraday::ConnectionFailed
      raise NoResponse, '$metadata'
    end
  end
end
