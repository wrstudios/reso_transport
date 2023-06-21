$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'byebug'
require 'reso_transport'
require 'minitest/autorun'
require 'minitest/rg'

require 'yaml'
SECRETS = YAML.load_file('secrets.yml')

