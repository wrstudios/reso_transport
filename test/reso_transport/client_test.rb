require 'test_helper'

class ResoTransport::ClientTest < Minitest::Test

  def config
    SECRETS
  end

  def client
    @client ||= ResoTransport::Client.new(config)
  end

  def test_all_clients
    SECRETS.each_pair do |key, config|
      client = ResoTransport::Client.new(config)

      assert client.resources.size > 0
      prop = client.resources["Property"]
      assert prop

      if prop.properties.size == 0
        skip("No Propery fields for #{key}")
      else
        assert prop.properties.size > 0
      end

      VCR.use_cassette("#{key}_test_queries") do
        begin
          query = prop.query
          query.include(*prop.expandable.map(&:name)) if prop.expandable.any?
          query.ge(ModificationTimestamp: "2019-12-04T00:00:00-07:00")
          query.limit(1)
            
          results = query.results

          assert_equal 1, results.size

          listing = results.first

          if listing['Media'].size != listing['PhotosCount']
            skip("Media array and PhotosCount DONT MATCH for #{key}")
          else
            assert_equal listing['Media'].size, listing['PhotosCount']
          end

          assert listing['ListPrice'] > 0
        rescue => e
          skip(e.to_s)
        end

      end
    end
  end

end

