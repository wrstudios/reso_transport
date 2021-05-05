module ResoTransport
  class MetadataCache
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def read
      return nil if !File.exist?(name) || File.size(name).zero?

      File.new(name)
    end

    def write(raw)
      File.open(name, 'w') { |f| f.write(raw.force_encoding('UTF-8')) } if raw.length.positive?
      File.new(name)
    end
  end
end
