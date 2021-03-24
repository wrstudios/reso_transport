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
      prop = nil
      log_io = StringIO.new
      logger = Logger.new(log_io)
      config[:logger] = logger

      VCR.use_cassette("#{key}_test_resources") do
        client = ResoTransport::Client.new(config)

        assert client.resources.size > 0
        prop = client.resources["Property"]
        assert prop

        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts log_io.string
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

        if prop.properties.size == 0
          skip("No Propery fields for #{key}")
        else
          assert prop.properties.size > 0
        end
      end

      # VCR.use_cassette("#{key}_test_queries") do
      #   query = prop.query
      #   query.expand(*prop.expandable.map(&:name)) if prop.expandable.any?
      #   query.ge(ModificationTimestamp: "2019-12-04T00:00:00-07:00")
      #   query.limit(1)

      #   results = query.results

      #   assert_equal 1, results.size

      #   listing = results.first

      #   #assert_equal listing['Media'].size, listing['PhotosCount']
      #   assert listing['ListPrice'] > 0

      #   # byebug
      # end

      # VCR.use_cassette("#{key}_test_counts") do
      #   query = prop.query
      #   query.ge(ModificationTimestamp: "2019-12-04T00:00:00-07:00")

      #   assert query.count > 0
      # end
    end
  end

end

