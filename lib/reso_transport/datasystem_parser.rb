module ResoTransport
  class DatasystemParser
    def parse(doc)
      begin
        data = doc.is_a?(File) ? doc.read : doc
        @json = JSON.parse data
      rescue JSON::ParserError => e
        @json = {}
        puts e.message
      end
      self
    end

    # value ->
    #   Resources ->
    #     Name ->
    #     ResourcePath ->
    #     Localizations ->
    #       Name ->
    #       ResourcePath ->

    def resources
      @resources ||= @json['value'].map { |v| v['Resources'] }.flatten.map { |r| [r['Name'], r] }.to_h
    end
  end
end
