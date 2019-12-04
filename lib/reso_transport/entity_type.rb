module ResoTransport
  EntityType = Struct.new(:name, :base_type, :primary_key, :schema) do

    def self.from_stream(args)
      new(args["Name"], args["BaseType"])
    end

    def parse(record)
      record.each_pair do |k,v|
        next if v.nil?
        if property = (property_map[k] || navigation_property_map[k])
          record[k] = property.parse(v)
        end
      end
    end

    def parse_value(record, parent_property)
      record.each_pair do |k,v|
        next if v.nil?
        if property = (property_map[k] || navigation_property_map[k])
          record[k] = property.parse(v)
        end
      end
    end

    def property_map
      @property_map ||= properties.inject({}) {|hsh, p| hsh[p.name] = p; hsh }
    end

    def properties
      @properties ||= []
    end

    def navigation_property_map
      @navigation_property_map ||= navigation_properties.inject({}) {|hsh, p| hsh[p.name] = p; hsh }
    end

    def navigation_properties
      @navigation_properties ||= []
    end

    def enumerations
      @enumerations ||= []
    end

  end
end
