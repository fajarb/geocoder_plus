require 'geokit'
require 'geokit/geocoders.rb'
require 'geocoder'
require 'yajl'
require 'geocoders/yahoo_place_finder_geocoder'
require 'geocoders/google_v3_geocoder'



# finally, set up the http service Koala methods used to make requests
# you can use your own (for HTTParty, etc.) by calling Koala.http_service = YourModule
# def self.http_service=(service)
#   self.send(:include, service)
# end

module GeocoderPlus
  
  # by default, try requiring api_cache -- if that works, use it
  begin
    require 'api_cache'
  rescue LoadError
    puts "APICache is not installed. Install it to enable query caching, gem install 'api_cache'"
  end
end