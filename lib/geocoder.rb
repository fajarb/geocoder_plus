module Geokit
  module Geocoders
    
    @@cache = nil
    @@hydra = nil
    __define_accessors

    # The Geocoder base class which defines the interface to be used by all
    # other geocoders.
    class Geocoder
      
      private
      
      def self.cache_query
        @_cache ||= initialize_cache
      end
      
      # Set hydra and memcache if defined in configuration file
      def self.initialize_cache        
        if (Geokit::Geocoders::cache && Geokit::Geocoders::hydra)
          @cache = Geokit::Geocoders::cache
          Geokit::Geocoders::hydra.cache_setter do |request|
            @cache.set(request.cache_key, request.response, request.cache_timeout)
          end

          Geokit::Geocoders::hydra.cache_getter do |request|
            @cache.get(request.cache_key) rescue nil
          end
          return true
        end
      end
      
      # Wraps the geocoder call around a proxy if necessary.
      # Use typhoeus and memcache if defined
      def self.do_get(url)
        uri = URI.parse(url)
        if (cache_query)
          req = Typhoeus::Request.new(url, :cache_timeout => 604800) # cache response for 1 week
          Geokit::Geocoders::hydra.queue(req)
          Geokit::Geocoders::hydra.run
          return req.response
        else     
          req = Net::HTTP::Get.new(url)
          req.basic_auth(uri.user, uri.password) if uri.userinfo
          res = Net::HTTP::Proxy(GeoKit::Geocoders::proxy_addr,
                  GeoKit::Geocoders::proxy_port,
                  GeoKit::Geocoders::proxy_user,
                  GeoKit::Geocoders::proxy_pass).start(uri.host, uri.port) { |http| http.get(uri.path + "?" + uri.query) }
          return res
        end
      end
    end
    
  end  
end
