require 'test_helper'

module ResoTransport
  class ClientTest < Minitest::Test
    def test_all_clients
      SECRETS.each_pair do |key, config|
        prop = nil
        log_io = StringIO.new
        logger = Logger.new(log_io)
        config[:logger] = logger

        VCR.use_cassette("#{key}_test_resources") do
          client = Client.new(config)

          assert client.resources.size.positive?
          prop = client.resources['Property'] || client.resources['PropertyResi']
          assert prop

          if prop.properties.size.zero?
            skip("No Propery fields for #{key}")
          else
            assert prop.properties.size.positive?
          end
        end
      end
    end
  end
end
