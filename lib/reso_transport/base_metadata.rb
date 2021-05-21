module ResoTransport
  class BaseMetadata
    MIME_TYPES = {
      xml: 'application/xml',
      json: 'application/json'
    }.freeze

    attr_reader :client

    def initialize(client)
      @client = client
      @prefix = nil
      @classname = nil
    end

    def prefix
      raise 'prefix not set' unless @prefix

      @prefix
    end

    def classname
      raise 'classname not set' unless @classname

      @classname
    end

    def parser
      @parser ||= Object::const_get("#{classname}Parser").new.parse(data)
    end

    def data
      if cache_file
        cache.read || cache.write(raw)
      else
        raw
      end
    end

    def cache
      @cache ||= client.send("#{prefix}_cache").new(cache_file)
    end

    def cache_file
      @cache_file ||= client.send "#{prefix}_file"
    end

    def raw
      return response.body if response.success?

      raise RequestError.new(response, classname)
    end

    def response
      raise 'Must implement response method'
    end
  end
end
