module ResoTransport
  Metadata = Struct.new(:client) do 

    MIME_TYPES = {
      xml: "application/xml",
      json: "application/json"
    }

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
          raw_md = raw
          File.open(client.md_file, "w") {|f| f.write(raw.force_encoding("UTF-8")) } unless raw_md.length == 0
          File.new(client.md_file)
        end
      else
        raw
      end
    end

    def raw
      resp = client.connection.get("$metadata") do |req|
        req.headers['Accept'] = MIME_TYPES[client.vendor.fetch(:metadata_format, :xml).to_sym]
      end

      if resp.success?
        resp.body
      else
        puts resp.body
        raise "Error getting metadata!"
      end
    end

  end
end
