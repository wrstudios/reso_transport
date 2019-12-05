require 'test_helper'

class ResoTransport::QueryTest < Minitest::Test
  def config
    SECRETS[:bridge]
  end

  def client
    @client ||= ResoTransport::Client.new(config)
  end

  def query
    client.resources["Property"].query
  end

  # Test all the easy stuff first
  def test_limit
    expected = { "$top" => 1 }
    assert_equal expected, query.limit(1).compile_params 
  end

  def test_limit_offset
    expected = { "$top" => 1, "$skip" => 10 }
    assert_equal expected, query.limit(1).offset(10).compile_params 
  end

  def test_include_count
    expected = { "$top" => 1, "$count" => true }
    assert_equal expected, query.limit(1).include_count.compile_params
  end

  def test_select_fields
    expected = { "$select" => "One,Two" }

    assert_equal expected, query.select(:One).select(:Two).compile_params
    assert_equal expected, query.select("One").select("Two").compile_params
    assert_equal expected, query.select("One", "Two").compile_params
    assert_equal expected, query.select(["One", "Two"]).compile_params
  end

  def test_expand
    expected = { "$expand" => "One,Two" }

    assert_equal expected, query.expand(:One).expand(:Two).compile_params
    assert_equal expected, query.expand("One").expand("Two").compile_params
    assert_equal expected, query.expand("One", "Two").compile_params
    assert_equal expected, query.expand(["One", "Two"]).compile_params
  end

  def test_ordering
    expected = { "$orderby" => "Mod" }
    assert_equal expected, query.order(:Mod).compile_params

    expected = { "$orderby" => "Mod desc" }
    assert_equal expected, query.order(:Mod, :desc).compile_params
  end


  # Test Filtering
  def test_filters
    expected = { "$filter" => "City eq 'Brea'" }
    sample = query.eq(City: 'Brea').compile_params
    assert_equal expected, sample

    expected = { "$filter" => "City ne 'Brea'" }
    sample = query.ne(City: 'Brea').compile_params
    assert_equal expected, sample

    expected = { "$filter" => "City eq 'Brea' and ListPrice eq 100" }
    sample = query.eq(City: 'Brea').eq(ListPrice: 100).compile_params
    assert_equal expected, sample

    sample = query.all {
      eq(City: 'Brea').ge(ListPrice: 100).le(ListPrice: 200)
    }.compile_params
    
    expected = { "$filter" => "(City eq 'Brea' and ListPrice ge 100 and ListPrice le 200)" }
    assert_equal expected, sample

    sample = query.any {
      eq(City: 'Brea').ge(ListPrice: 100)
    }.compile_params
    
    expected = { "$filter" => "(City eq 'Brea' or ListPrice ge 100)" }
    assert_equal expected, sample

    sample = query.any {
      eq(City: 'Brea').eq(City: 'Yorba Linda')
    }.all {
      eq(PropertyType: 'Residential').le(ListPrice: 200)
    }.compile_params
    
    expected = { "$filter" => "(City eq 'Brea' or City eq 'Yorba Linda') and (PropertyType eq 'Residential' and ListPrice le 200)" }
    assert_equal expected, sample
  end

end
