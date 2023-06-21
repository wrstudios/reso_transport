require 'test_helper'

module ResoTransport
  class ClientTest < Minitest::Test
    def configure(config)
      log_io = StringIO.new
      logger = Logger.new(log_io)
      config[:logger] = logger
    end

    def test_all_clients
      SECRETS.each_pair do |key, config|
        configure config

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

    def test_no_response
      key = SECRETS.keys.first
      config = SECRETS[key].dup
      configure config
      config[:md_file] = nil
      config[:endpoint] = 'http://non-existent-url'

      client = Client.new(config)

      assert_raises NoResponse do
        client.resources.size
      end
    end

    def test_request_error
      key = SECRETS.keys.first
      config = SECRETS[key].dup
      configure config
      config[:md_file] = nil
      config[:endpoint] = 'http://httpstat.us/400'

      client = Client.new(config)

      assert_raises RequestError do
        client.resources.size
      end
    end
  end
end
