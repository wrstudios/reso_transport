module ResoTransport
  Property = Struct.new(:name, :data_type, :attrs, :multi, :enum, :complex_type, :entity_type) do

    def self.from_stream(args)
      new(args["Name"], args["Type"], args)
    end

    def parse(value)
      case value
      when Array
        value.map {|v| parser_object.parse_value(v) }
      else
        if multi
          value.split(',').map(&:strip).map {|v| parser_object.parse_value(v) }
        else
          parser_object.parse_value(value)
        end
      end
    end

    def parse_value(value)
      case data_type
      when "Edm.DateTimeOffset"
        DateTime.parse(value)
      when "Edm.Date"
        Date.parse(value)
      else
        value
      end
    end

    def encode(value)
      case value
      when Array
        value.map {|v| parser_object.encode_value(v) }
      else
        parser_object.encode_value(value)
      end
    end

    def encode_value(value)
      case data_type
      when "Edm.String"
        "'#{value}'"
      when "Edm.DateTimeOffset"
        if value.respond_to?(:to_datetime)
          value.to_datetime.strftime(ODATA_TIME_FORMAT)
        else
          DateTime.parse(value).strftime(ODATA_TIME_FORMAT)
        end
      else
        value
      end
    end

    def parser_object
      enum || complex_type || entity_type || self
    end

    def finalize_type(parser)
      type_name, is_collection = case self.data_type
      when /^Collection\((.*)\)$/ 
        [$1, true]
      when /^Edm\.(.*)$/
        [$1, false]
      else
        [self.data_type, false]
      end

      if enum = parser.enumerations.detect {|e| e.name == type_name }
        self.multi = is_collection || enum.is_flags
        self.enum = enum
      end

      schema_name, collection_name = ResoTransport.split_schema_and_class_name(type_name)
      if schema = parser.schemas.detect {|e| e.namespace == schema_name }
        if complex_type = schema.complex_types.detect {|c| c.name == collection_name }
          self.multi = is_collection
          self.complex_type = complex_type
        end

        if entity_type = schema.entity_types.detect {|et| et.name == collection_name }
          self.multi = is_collection
          self.entity_type = entity_type
        end
      end

    end

    def method_missing(name, *args, &block)
      self.attrs[name] || self.attrs[camelize(name)] || super
    end

    private

    def camelize(name)
      name.to_s.split("_").map(&:capitalize).join
    end

  end
end
