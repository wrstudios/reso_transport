require 'test_helper'

class ResoTransport::BridgeTest < Minitest::Test

  def config
    SECRETS[:bridge]
  end

  def client
    @client ||= ResoTransport::Client.new(config)
  end

  def test_resources
    assert client.resources.size > 0

    prop = client.resources["Property"]
    assert prop

    assert prop.entity_type
    assert_equal 316, prop.entity_type.properties.size
  end

  def test_query
    VCR.use_cassette("bridge_test_query") do
      results = client.resources["Property"].query.ge(ModificationTimestamp: "2019-12-04T00:00:00-07:00").limit(1).results
      assert_equal 1, results.size

      listing = results.first
      assert listing['PhotosCount'].size > 0
      assert_equal listing['Media'].size, listing['PhotosCount']

      assert_equal ["Cook Top","Dishwasher"], listing['Appliances']
      assert listing['ListPrice'] > 0

    end
  end

end
