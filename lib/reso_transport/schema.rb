module ResoTransport
  Schema = Struct.new(:namespace) do

    def self.from_stream(args)
      new(args["Namespace"])
    end

    def entity_types
      @entity_types ||= []
    end

    def complex_types
      @complex_types ||= []
    end

    def enumerations
      @enumerations ||= []
    end

  end
end
