module ResoTransport
  Metadata = Struct.new(:client) do 

    def entity_sets
      parser.entity_sets
    end

    def schemas
      parser.schemas
    end

    def parser
      @parser ||= MetadataParser.new.parse(get_data)
    end

    def get_data
      if client.md_file 
        if File.exist?(client.md_file) && File.size(client.md_file) > 0
          File.new(client.md_file)
        else
          File.open(client.md_file, "w") {|f| f.write(raw) }
          File.new(client.md_file)
        end
      else
        raw
      end
    end

    def raw
      resp = client.connection.get("$metadata") do |req|
        req.headers['Accept'] = 'application/xml' if client.vendor.fetch(:force_xml_metadata, false)
        req.headers['Accept'] = 'application/json' if client.vendor.fetch(:force_json_metadata, false)
      end

      if resp.success?
        resp.body
      else
        raise "Error getting metadata!"
      end
    end

  end
end
