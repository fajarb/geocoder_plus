# this code is taken from https://github.com/tello/google-v3-geocoder

module Geokit
  module Geocoders
    class GoogleV3Geocoder < Geocoder

      private
      
      def self.success_response?(res)
        if res.is_a?(Typhoeus::Response)
          return res.success?
        else
          return res.is_a?(Net::HTTPSuccess)
        end
      end
      
      def self.get_url(address, options={})
        bias = options[:bias] || ''
        address_str = address.is_a?(GeoLoc) ? address.to_geocodeable_s : address
        return "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{Geokit::Inflector::url_escape(address_str)}&region=#{bias.to_s.downcase}"
      end

      def self.do_geocode(address, options = {})
        geo_url = self.get_url(address, options)
        logger.debug "Making Geocode request to:  #{geo_url}"
        res = self.call_geocoder_service(geo_url)        
        logger.debug "Google V3 geocoding. Address: #{address}. Result: #{res}"
        
        if success_response?(res)
          return self.parse_body(Yajl::Parser.parse(res.body))
        else
          return GeoLoc.new
        end
      rescue 
        logger.info "Caught an error during Google V3 geocoding call: "+$!
        return GeoLoc.new
      end

      def self.parse_body(body)    
        if body['status'] != "OK"
          if body['status' ] == 'OVER_QUERY_LIMIT'
            raise Geokit::TooManyQueriesError "Google returned OVER_QUERY_LIMIT: #{body}"
          elsif body['status'] == 'ZERO_RESULTS'
            logger.info "Found no results from google v3"
            return GeoLoc.new
          end
          logger.error "Got an error from google, response: #{body}"
          # Otherwise, we don't know what to do
          return GeoLoc.new
        end

        begin
          results = body['results']
          geoloc = nil
          results.each do |result|
            extracted_geoloc = self.extract_location(result)
            if geoloc.nil?
              geoloc = extracted_geoloc
            else
              geoloc.all.push(extracted_geoloc)
            end
          end
        rescue Exception => e
          logger.error "Encountered unexpected exception during google geocoding: #{e.inspect}"
          return GeoLoc.new
        end

        return geoloc
      end
  
      def self.extract_location(result)
        res = GeoLoc.new
        res.provider = 'google_v3'
    
        res.lat = result['geometry']['location']['lat']
        res.lng = result['geometry']['location']['lng']

        res.full_address = result['formatted_address']

        street_number = nil
        street_name = nil

        result['address_components'].each do |component|
          types = component['types']

          if types.include?('street_number')
            street_number = component['long_name']
          end

          if types.include?('route')
            street_name = component['long_name']
          end

          if types.include?('country')
            res.country = component['long_name']
            res.country_code = component['short_name']
          end

          if types.include?('administrative_area_level_1')
            res.state = component['short_name']
          end

          if types.include?('postal_code')
            res.zip = component['long_name']
          end

          if types.include?('locality')
            res.city = component['long_name']
          end

          if types.include?('postal_code')
            res.zip = component['long_name']
          end
      
        end
        res.street_address = [street_number, street_name].reject{|x| x.nil?}.join(" ")

        # Set the bounds from the viewport
        bounds = result['geometry']['viewport']
        res.suggested_bounds = Bounds.normalize(
          [bounds['southwest']['lat'], bounds['southwest']['lng']],
          [bounds['northeast']['lat'], bounds['northeast']['lng']]
        )

        res.success = true
        return res
      end
    end
  end
end