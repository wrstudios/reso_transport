require 'test_helper'

module ResoTransport
  class DatasystemTest < Minitest::Test
    def test_rapattoni_datasystem
      vendor = :rapattoni

      VCR.use_cassette("#{vendor}_test_resources") do
        client = Client.new(SECRETS[vendor])
        assert client.metadata.entity_sets.size.positive?
        assert client.metadata.datasystem?

        properties = client.resources['Property']
        assert properties
        assert properties.localizations.any?

        assert_raises StandardError do
          properties.query.limit(1).results
        end

        results = properties.localization('Residential').query.limit(1).results
        assert results
      end
    end
  end
end
