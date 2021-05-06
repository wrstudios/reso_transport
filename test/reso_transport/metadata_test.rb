require 'test_helper'

class ResoTransport::MetadataTest < Minitest::Test
  def test_bridge_metadata
    vendor = :bridge

    VCR.use_cassette("#{vendor}_metadata") do
      client = ResoTransport::Client.new(SECRETS[vendor])
      assert client.metadata.entity_sets.size > 0

      # verify we have a "Property" entity set (exposed resource)
      prop_set = client.metadata.entity_sets.detect { |es| es.name == 'Property' }
      assert prop_set

      # verify we can get from the entity set's type to the actual entity type (via the schema)
      schema = client.metadata.schemas.detect { |s| s.namespace == prop_set.schema }
      assert schema

      ent_type = schema.entity_types.detect { |et| et.name == prop_set.entity_type }
      assert ent_type
      assert ent_type.properties.size > 100

      # get a field with enumerations and make sure it will map values
      field = ent_type.properties.detect { |p| p.name == 'Appliances' }
      assert field
      assert field.enum
      assert field.multi
      assert_equal 'Appliance Center', field.enum.parse_value('Appliance Center')

      media = client.resources['Property'].properties.detect { |p| p.name == 'Media' }.complex_type
      assert media
    end
  end

  def test_trestle_metadata
    vendor = :trestle

    VCR.use_cassette("#{vendor}_metadata") do
      client = ResoTransport::Client.new(SECRETS[vendor])
      assert client.metadata.entity_sets.size > 0

      # verify we have a "Property" entity set (exposed resource)
      prop_set = client.metadata.entity_sets.detect { |es| es.name == 'Property' }
      assert prop_set

      # verify we can get from the entity set's type to the actual entity type (via the schema)
      schema = client.metadata.schemas.detect { |s| s.namespace == prop_set.schema }
      assert schema

      ent_type = schema.entity_types.detect { |et| et.name == prop_set.entity_type }
      assert ent_type
      assert ent_type.properties.size > 500

      # get a field with enumerations and make sure it will map values
      field = ent_type.properties.detect { |p| p.name == 'Appliances' }
      assert field
      assert field.enum
      assert field.multi
      assert_equal 'Bar Fridge', field.enum.parse_value('BarFridge')
    end
  end
end
