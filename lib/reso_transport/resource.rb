module ResoTransport
  Resource = Struct.new(:client, :entity_set, :localizations, :local) do
    def query
      Query.new(self)
    end

    def name
      entity_set.name
    end

    def property(name)
      properties.detect { |p| p.name == name }
    end

    def properties
      entity_type.properties
    end

    def expandable
      entity_type.navigation_properties
    end

    def entity_type
      @entity_type ||= schema.entity_types.detect { |et| et.name == entity_set.entity_type }
    end

    def schema
      @schema ||= md.schemas.detect { |s| s.namespace == entity_set.schema }
    end

    def md
      client.metadata
    end

    def parse(results)
      results.map { |r| entity_type.parse(r) }
    end

    def get(params)
      client.connection.get(url, params) do |req|
        req.headers['Accept'] = 'application/json'
        @request = req
      end
    end

    def url
      return local['ResourcePath'].gsub(%r{^/}, '') if local

      raise LocalizationRequired, self if localizations.any? && local.nil?

      return "#{name}/replication" if client.use_replication_endpoint

      name
    end

    def localization(name)
      self.local = localizations[name] if localizations.key?(name)
      self
    end

    def to_s
      %(#<ResoTransport::Resource entity_set="#{name}", schema="#{schema&.namespace}">)
    end

    def inspect
      to_s
    end

    def request
      return @request.to_h if @request.respond_to? :to_h

      {}
    end
  end
end
