$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "byebug"
require "reso_transport"
require "minitest/autorun"
require "minitest/rg"

require 'yaml'
SECRETS = YAML.load_file("secrets.yml")

require 'vcr'
VCR.configure do |config|
  # config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday
end

