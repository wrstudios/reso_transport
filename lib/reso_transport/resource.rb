module ResoTransport
  Resource = Struct.new(:client, :entity_set) do

    def query
      Query.new(self)
    end

    def name
      entity_set.name
    end

    def property(name)
      properties.detect {|p| p.name == name }
    end

    def properties
      entity_type.properties
    end

    def expandable
      entity_type.navigation_properties
    end
    
    def entity_type
      @entity_type ||= schema.entity_types.detect {|et| et.name == entity_set.entity_type }
    end

    def schema
      @schema ||= md.schemas.detect {|s| s.namespace == entity_set.schema }
    end

    def md
      client.metadata
    end

    def parse(results)
      results.map {|r| entity_type.parse(r) }
    end

    def get(params)
      client.connection.get(name, params) do |req|
        req.headers['Accept'] = 'application/json'
      end
    end

    def to_s
      %(#<ResoTransport::Resource entity_set="#{name}", schema="#{schema&.namespace}">)
    end

    def inspect
      to_s
    end

  end
end
