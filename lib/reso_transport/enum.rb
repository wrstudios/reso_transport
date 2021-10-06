module ResoTransport
  Member = Struct.new(:name, :value, :annotation) do
    def self.from_stream(args)
      new(args["Name"], args["Value"])
    end
  end

  Enum = Struct.new(:name, :type, :is_flags) do
    def self.from_stream(args)
      new("#{args[:schema].namespace}.#{args["Name"]}", args["UnderlyingType"], args["IsFlags"].to_s.downcase == "true")
    end
    
    def members
      @members ||= []
    end

    def parse_value(value)
      mapping.fetch(value, value)
    end

    def encode_value(value)
      "'#{value}'"
    end
  end
end

