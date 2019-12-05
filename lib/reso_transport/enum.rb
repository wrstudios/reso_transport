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

    def parse_value(value)
      mapping.fetch(value, value)
    end

    def encode_value(value)
      "'#{mapping.invert.fetch(value, value)}'"
    end

    def mapping
      @mapping ||= generate_member_map || {}
    end

    def generate_member_map
      members.map {|mem|
        { mem.name => mem.annotation || mem.name }  
      }.reduce(:merge!)
    end

  end
end

