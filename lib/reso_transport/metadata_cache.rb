module ResoTransport
  class MetadataCache
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def read
      if File.exist?(name) && File.size(name) > 0
        File.new(name)
      end
    end

    def write(raw)
      File.open(name, "w") {|f| f.write(raw.force_encoding("UTF-8")) } unless raw.length == 0
      File.new(name)
    end

  end
end
