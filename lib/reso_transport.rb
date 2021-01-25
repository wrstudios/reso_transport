require 'rexml/document'
require 'rexml/streamlistener'
require 'logger'
require 'faraday'
require 'json'
require 'time'

require "reso_transport/version"
require "reso_transport/configuration"
require "reso_transport/authentication"
require "reso_transport/client"
require "reso_transport/resource"
require "reso_transport/metadata"
require "reso_transport/metadata_parser"
require "reso_transport/schema"
require "reso_transport/entity_set"
require "reso_transport/entity_type"
require "reso_transport/enum"
require "reso_transport/property"
require "reso_transport/query"



# module Faraday
#   module Utils

#     def escape(str)
#       str.to_s.gsub(ESCAPE_RE) do |match|
#         '%' + match.unpack('H2' * match.bytesize).join('%').upcase
#       end.gsub(" ","%20")

#     end
#   end
# end

Faraday::Utils.default_space_encoding = "%20"

module ResoTransport
  class Error < StandardError; end
  class AccessDenied < StandardError; end
  ODATA_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S%Z"

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.split_schema_and_class_name(s)
    s.to_s.partition(/(\w+)$/).first(2).map {|s| s.sub(/\.$/, '') }
  end

end
