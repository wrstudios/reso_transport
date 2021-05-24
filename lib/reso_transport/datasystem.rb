require_relative 'base_metadata'

module ResoTransport
  class Datasystem < BaseMetadata
    def initialize(client)
      super client
      @prefix = 'ds'
      @classname = self.class.name
    end

    def localizations_for(resource_name)
      localizations = parser.resources.dig(resource_name, 'Localizations') || []
      localizations.map { |l| [l['Name'], l] }.to_h
    end

    def response
      @response ||= client.connection.get('DataSystem') do |req|
        req.headers['Accept'] = 'application/json'
        @request = req
      end
    rescue Faraday::ConnectionFailed
      raise NoResponse.new(request, nil, 'DataSystem')
    end
  end
end
