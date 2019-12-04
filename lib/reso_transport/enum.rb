module ResoTransport
  Member = Struct.new(:name, :value, :annotation) do
    def self.from_stream(args)
      new(args["Name"], args["Value"])
    end
  end

  Enum = Struct.new(:name, :type, :is_flags) do
    def self.from_stream(args)
      new("#{args[:schema].namespace}.#{args["Name"]}", args["UnderlyingType"], args["IsFlags"])
    end
    
    def members
      @members ||= []
    end

    def parse_value(value, property)
      if property.multi
        arr_value = case value
        when Array
          value
        when String
          value.split(',').map(&:strip) 
        end
        arr_value.map {|v| map_value(v) }
      else
        map_value(value)
      end
    end

    def encode_value(value, property)
      if property.multi
        arr_value = case value
        when Array
          value
        when String
          value.split(',').map(&:strip) 
        end
        "'#{arr_value.map {|v| enum.map_encoded_value(v) }.join(",")}'"
      else
        "'#{enum.map_encoded_value(value)}'"
      end
    end

    def map_value(val)
      mapping.fetch(val, val)
    end

    def map_encoded_value(val)
      mapping.invert.fetch(val, val)
    end

    def mapping
      @mapping ||= generate_member_map || {}
    end

    def generate_member_map
      members.select {|mem|
        !!mem.annotation
      }.map {|mem|
        { mem.name => mem.annotation || mem.name }  
      }.reduce(:merge!)
    end

  end
end

