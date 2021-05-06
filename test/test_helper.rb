$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'byebug'
require 'reso_transport'
require 'minitest/autorun'
require 'minitest/rg'

require 'yaml'
SECRETS = YAML.load_file('secrets.yml')

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :faraday
  config.default_cassette_options = {
    record: :new_episodes
  }
end
