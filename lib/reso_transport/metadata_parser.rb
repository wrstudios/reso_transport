module ResoTransport
  class MetadataParser
    include REXML::StreamListener

    attr_reader :schemas, :entity_sets, :enumerations

    def initialize
      @schemas = []
      @entity_sets = []
      @entity_types = []
      @enumerations = []

      @current_entity_type = nil
      @current_complex_type = nil
      @current_enum_type = nil
      @current_member = nil
    end

    def parse(doc)
      REXML::Document.parse_stream(doc, self)
      finalize
      return self
    end

    def finalize
      schemas.each do |s|
        s.entity_types.each do |et|
          et.properties.each do |p|
            p.finalize_type(self)
          end
        end

        s.complex_types.each do |et|
          et.properties.each do |p|
            p.finalize_type(self)
          end
        end
      end
    end

    # Schema ->
    #   EnumType ->
    #     Members ->
    #       Annotation
    #   EntityType ->
    #     Key
    #     Properties ->
    #       enumerations
    #

    def tag_start(name, args)
      case name
      when "Schema"
        @schemas << ResoTransport::Schema.from_stream(args)
      when "EntitySet"
        @entity_sets << ResoTransport::EntitySet.from_stream(args)
      when "EntityType"
        @current_entity_type = ResoTransport::EntityType.from_stream(args)
      when "ComplexType"
        @current_complex_type = ResoTransport::EntityType.from_stream(args)
      when "PropertyRef"
        @current_entity_type.primary_key = args['Name']
      when "Property"
        @current_entity_type.properties << ResoTransport::Property.from_stream(args.merge(schema: @schemas.last)) if @current_entity_type
        @current_complex_type.properties << ResoTransport::Property.from_stream(args.merge(schema: @schemas.last)) if @current_complex_type
      when "NavigationProperty"
        @current_entity_type.navigation_properties << ResoTransport::Property.from_stream(args)
      when "EnumType"
        @current_enum_type = ResoTransport::Enum.from_stream(args.merge(schema: @schemas.last))
      when "Member"
        @current_member = ResoTransport::Member.from_stream(args)
      when "Annotation"
        if @current_enum_type && @current_member
          @current_member.annotation = args['String']
        end
      end
    rescue => e
      puts e.inspect
      puts "Error processing Tag: #{[name, args].inspect}"
    end

    def tag_end(name)
      case name
      when "EntityType"
        @current_entity_type.schema = @schemas.last.namespace
        @schemas.last.entity_types << @current_entity_type
      when "ComplexType"
        @current_complex_type.schema = @schemas.last.namespace
        @schemas.last.complex_types << @current_complex_type
      when "EnumType"
        @enumerations << @current_enum_type
        @current_enum_type = nil
      when "Member"
        @current_enum_type.members << @current_member
        @current_member = nil
      end
    end

  end
end
