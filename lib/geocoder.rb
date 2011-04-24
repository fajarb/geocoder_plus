module Geokit
  module Geocoders
    
    @@api_cache = nil
    @@api_cache_valid = 86400
    @@api_cache_timeout = 5

    __define_accessors

    # The Geocoder base class which defines the interface to be used by all
    # other geocoders.
    class Geocoder
      
      def self.normalize_address(addr)
        addr.gsub(/\s*,\s*/, ',').strip
      end
      
      private
            
      # Wraps the geocoder call around a proxy if necessary.
      # Use typhoeus and memcache if defined
      def self.do_get(url)        
        if (defined?(APICache) && Geokit::Geocoders::api_cache)
          body = APICache.get(url, {
                  :cache   => Geokit::Geocoders::api_cache,
                  :valid   => Geokit::Geocoders::api_cache_valid,
                  :timeout => Geokit::Geocoders::api_cache_timeout})
          # fake Net::HTTPOK so that caching will work for all geocoders
          res = Net::HTTPOK.new(1.0, 200, 'OK')
          res.instance_variable_set(:@body, body)
          res.instance_variable_set(:@read, true)          
        else
          uri = URI.parse(url)
          req = Net::HTTP::Get.new(url)
          req.basic_auth(uri.user, uri.password) if uri.userinfo
          res = Net::HTTP::Proxy(GeoKit::Geocoders::proxy_addr,
                  GeoKit::Geocoders::proxy_port,
                  GeoKit::Geocoders::proxy_user,
                  GeoKit::Geocoders::proxy_pass).start(uri.host, uri.port) { |http| http.get(uri.path + "?" + uri.query) }          
        end
        return res
      end
    end
    
  end  
end
