$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "byebug"
require "reso_transport"
require "minitest/autorun"

require 'yaml'
SECRETS = YAML.load_file("secrets.yml")

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday
end

