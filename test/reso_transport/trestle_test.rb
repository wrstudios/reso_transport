require 'test_helper'

class ResoTransport::TrestleTest < Minitest::Test

  def config
    SECRETS[:trestle]
  end

  def client
    @client ||= ResoTransport::Client.new(config)
  end

  def test_resources
    assert client.resources.size > 0

    prop = client.resources["Property"]
    assert prop

    assert prop.entity_type
    assert_equal 612, prop.entity_type.properties.size
  end

  def test_query
    VCR.use_cassette("trestle_test_query") do
      resource = client.resources["Property"]
      field = resource.property("PropertyType")

      assert_equal "'ResidentialLease'", field.parse_query_value("Residential Lease")

      assert resource
      assert field.enum


      listing = resource.query.eq(StandardStatus: 'Active', PropertyType: 'Residential Lease').limit(1).results.first

      assert listing
      assert_equal "Residential Lease", listing['PropertyType']
      assert_equal "Active", listing["StandardStatus"]
      assert listing['ListPrice'] > 0

    end
  end

end
