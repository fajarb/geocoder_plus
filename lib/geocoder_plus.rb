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
  
  @use_typhoeus = true
  
  # by default, try requiring Typhoeus -- if that works, use it
  # if you have Typheous and don't want to use it (or want another service),
  # you can run Koala.http_service = NetHTTPService (or MyHTTPService)
  begin
    require 'typhoeus'
  rescue LoadError
    puts "Typhoeus is not installed, using Net:HTTP. Install typhoeus to enable query caching."
  end
end