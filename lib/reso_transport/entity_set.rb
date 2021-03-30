module ResoTransport
  EntitySet = Struct.new(:name, :schema, :entity_type) do
    def self.from_stream(args)
      schema, entity_type = ResoTransport.split_schema_and_class_name(args['EntityType'])

      new(args['Name'], schema, entity_type)
    end
  end
end
