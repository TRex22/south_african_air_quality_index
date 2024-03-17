require 'httparty'
# require 'jwt'
require 'nokogiri'

require 'south_african_air_quality_index/constants'
require 'south_african_air_quality_index/version'

require 'south_african_air_quality_index/client'

module SouthAfricanAirQualityIndex
  class Error < StandardError; end
end
