module ResoTransport
  EntityType = Struct.new(:name, :base_type, :primary_key, :schema) do
    def self.from_stream(args)
      new(args['Name'], args['BaseType'])
    end

    def parse(record)
      record.each_pair do |k, v|
        next if v.nil?

        property = property_map[k] || navigation_property_map[k]
        record[k] = property.parse(v) if property
      end
    end

    def parse_value(record)
      record.each_pair do |k, v|
        next if v.nil?

        property = property_map[k] || navigation_property_map[k]
        record[k] = property.parse(v) if property
      end
    end

    def property_map
      @property_map ||= properties.each_with_object({}) { |p, hsh| hsh[p.name] = p; }
    end

    def properties
      @properties ||= []
    end

    def navigation_property_map
      @navigation_property_map ||= navigation_properties.each_with_object({}) { |p, hsh| hsh[p.name] = p; }
    end

    def navigation_properties
      @navigation_properties ||= []
    end

    def enumerations
      @enumerations ||= []
    end
  end
end
