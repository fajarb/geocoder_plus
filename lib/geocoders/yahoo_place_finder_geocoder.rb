module Geokit
  module Geocoders
    class YahooPlaceFinderGeocoder < Geocoder
      
      private
      
      def self.success_response?(res)
        if res.is_a?(Typhoeus::Response)
          return res.success?
        else
          return res.is_a?(Net::HTTPSuccess)
        end
      end
      
      def self.get_url(address, options={})        
        if (options[:reverse])
          latlng=LatLng.normalize(address)
          yql = "select * from geo.placefinder where text='#{latlng}' and gflags='R'"
        else
          address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
          yql = "select * from geo.placefinder where text='#{address}'"
        end
        return "http://query.yahooapis.com/v1/public/yql?q=#{Geokit::Inflector::url_escape(yql)}&format=json"
      end
      
      def self.do_reverse_geocode(latlng) 
        res = self.call_geocoder_service(self.get_url(latlng, :reverse => true))
        logger.debug "Yahoo PlaceFinder reverse-geocoding. LL: #{latlng}. Result: #{res}"
        
        if success_response?(res)
          return self.parse_body(Yajl::Parser.parse(res.body))
        else
          return GeoLoc.new
        end
      end
      
      def self.do_geocode(address, options={})
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        res = self.call_geocoder_service(self.get_url(address, options))
        logger.debug "Yahoo PlaceFinder geocoding. Address: #{address}. Result: #{res}"
        
        if success_response?(res)
          return self.parse_body(Yajl::Parser.parse(res.body))
        else
          return GeoLoc.new
        end
      rescue 
        logger.info "Caught an error during Yahoo PlaceFinder geocoding call: "+$!
        return GeoLoc.new
      end

      def self.parse_body(body)
        count = body['query']['count']
        if (count == 1)
          return extract_place(body['query']['results']['Result'])
        elsif (count > 1)
          results = body['query']['results']['Result']
          geoloc = nil
          results.each do |r|
            extracted_geoloc = extract_place(r)
            if geoloc.nil? 
              # first time through, geoloc is still nil, so we make it the geoloc we just extracted
              geoloc = extracted_geoloc 
            else
              # second (and subsequent) iterations, we push additional 
              # geoloc onto "geoloc.all" 
              geoloc.all.push(extracted_geoloc) 
            end  
          end
          return geoloc
        else
          return GeoLoc.new
        end
      end
      
      def self.extract_place(result)
        geoloc = GeoLoc.new

        # basics
        geoloc.lat            = result['latitude']
        geoloc.lng            = result['longitude']
        geoloc.country_code   = result['countrycode']
        geoloc.provider       = 'yahoo_place_finder'

        # extended -- false if not not available
        geoloc.street_address = result['line1']
        geoloc.city           = result['city']
        # geoloc.neighborhood   = result['neighborhood']        
        # geoloc.county         = result['county']      
        geoloc.zip            = result['postal']
        geoloc.country        = result['country']    
        # geoloc.quality        = result['quality']        
        # geoloc.woeid          = result['woeid']        
        # geoloc.woetype        = result['woetype']        
        if geoloc.is_us?
          geoloc.state = result['statecode']
        else
          geoloc.state = result['state']
        end
        case result['quality'].to_i
          when 9,10        then geoloc.precision = 'country'
          when 19..30      then geoloc.precision = 'state'
          when 39,40       then geoloc.precision = 'city'
          when 49,50       then geoloc.precision = 'neighborhood'
          when 59,60,64    then geoloc.precision = 'zip'
          when 74,75       then geoloc.precision = 'zip+4'
          when 70..72      then geoloc.precision = 'street'
          when 80..87      then geoloc.precision = 'address'
          when 62,63,90,99 then geoloc.precision = 'building'
          else 'unknown'
        end
        
        geoloc.accuracy = %w{unknown country state state city zip zip+4 street address building}.index(geoloc.precision)
        # geoloc.full_address = "#{geoloc.street_address}, #{result['line2']}, #{geoloc.country}" if (geoloc.street_address && result['line2'])

        # google returns a set of suggested boundaries for the geocoded result
        # if suggested_bounds = doc.elements['//LatLonBox']  
        #   res.suggested_bounds = Bounds.normalize(
        #                           [suggested_bounds.attributes['south'], suggested_bounds.attributes['west']], 
        #                           [suggested_bounds.attributes['north'], suggested_bounds.attributes['east']])
        # end

        geoloc.success = true

        return geoloc
      end
      
    end  
  end
end
