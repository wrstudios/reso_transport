module ResoTransport
  Property = Struct.new(:name, :data_type, :attrs, :multi, :enum, :complex_type) do

    def self.from_stream(args)
      new(args["Name"], args["Type"], args)
    end

    def parse(value)
      if enum
        if multi
          arr_value = case value
          when Array
            value
          when String
            value.split(',').map(&:strip) 
          end
          arr_value.map {|v| enum.map_value(v) }
        else
          enum.map_value(value)
        end
      else
        value
      end
    end

    def parse_query_value(value)
      if enum
        if multi
          arr_value = case value
          when Array
            value
          when String
            value.split(',').map(&:strip) 
          end
          "'#{arr_value.map {|v| enum.map_request_value(v) }.join(",")}'"
        else
          "'#{enum.map_request_value(value)}'"
        end
      else
        case data_type
        when "Edm.String"
          "'#{value}'"
        else
          value
        end
      end
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

      schema_name, complex_name = ResoTransport.split_schema_and_class_name(type_name)
      if schema = parser.schemas.detect {|e| e.namespace == schema_name }
        if complex_type = schema.complex_types.detect {|c| c.name == complex_name }
          self.multi = is_collection
          self.complex_type = complex_type
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
