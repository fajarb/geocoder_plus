# this code is taken from https://github.com/tello/google-v3-geocoder

require 'helper'

class GoogleV3GeocoderTest < Test::Unit::TestCase
  include Geokit
  
  GOOD_JSON = <<-JSON
{
  "status": "OK",
  "results": [ {
    "types": [ "street_address" ],
    "formatted_address": "1288 E Hillsdale Blvd, Foster City, CA 94404, USA",
    "address_components": [ {
      "long_name": "1288",
      "short_name": "1288",
      "types": [ "street_number" ]
    }, {
      "long_name": "E Hillsdale Blvd",
      "short_name": "E Hillsdale Blvd",
      "types": [ "route" ]
    }, {
      "long_name": "Foster City",
      "short_name": "Foster City",
      "types": [ "locality", "political" ]
    }, {
      "long_name": "San Mateo",
      "short_name": "San Mateo",
      "types": [ "administrative_area_level_3", "political" ]
    }, {
      "long_name": "San Mateo",
      "short_name": "San Mateo",
      "types": [ "administrative_area_level_2", "political" ]
    }, {
      "long_name": "California",
      "short_name": "CA",
      "types": [ "administrative_area_level_1", "political" ]
    }, {
      "long_name": "United States",
      "short_name": "US",
      "types": [ "country", "political" ]
    }, {
      "long_name": "94404",
      "short_name": "94404",
      "types": [ "postal_code" ]
    } ],
    "geometry": {
      "location": {
        "lat": 37.5684570,
        "lng": -122.2660670
      },
      "location_type": "ROOFTOP",
      "viewport": {
        "southwest": {
          "lat": 37.5653094,
          "lng": -122.2692146
        },
        "northeast": {
          "lat": 37.5716046,
          "lng": -122.2629194
        }
      }
    }
  } ]
}
  JSON

  def test_get_url_adds_bias_if_set
    bias = 'thefreakingus'
    result = Geokit::Geocoders::GoogleV3Geocoder.send :get_url, 'address', :bias => bias
    assert_match /&region=#{bias}/, result
  end

  def test_get_url_escapes_address
    address = '123 hotel street'
    result = Geokit::Geocoders::GoogleV3Geocoder.send :get_url, address
    assert_match /&address=#{Regexp.escape(Geokit::Inflector::url_escape(address))}/, result
  end
  
  def test_convert_json_to_geoloc_extracts_result_from_json
    result = Geokit::Geocoders::GoogleV3Geocoder.send :convert_json_to_geoloc, GOOD_JSON
    assert result.success
    assert_equal 1, result.all.size
    assert_equal '1288 E Hillsdale Blvd, Foster City, CA 94404, USA', result.full_address
  end

  def test_convert_json_to_geoloc_handles_empty_result_set
    empty_json = '{"status": "ZERO_RESULTS","results": [ ]}'
    result = Geokit::Geocoders::GoogleV3Geocoder.send :convert_json_to_geoloc, empty_json
    assert !result.success
    assert_equal 1, result.all.size
    assert_nil result.lat
    assert_nil result.lng
  end

  def test_convert_json_to_geoloc_calls_extract_location
    expected_geoloc = GeoLoc.new
    expected_geoloc.city = "SOME City"
    Geokit::Geocoders::GoogleV3Geocoder.expects(:extract_location).returns expected_geoloc

    result = Geokit::Geocoders::GoogleV3Geocoder.send :convert_json_to_geoloc, GOOD_JSON
    assert_equal result, expected_geoloc
  end

  def test_convert_json_to_handles_multiple_results
    address1 = 'add1'
    address2 = 'add2'
    
    input_data = {
      "status" => "OK",
      "results" =>
        [
        {
          "types" => [ "street_address" ],
          "formatted_address" => address1,
          "address_components" => [],
          "geometry" => {
            "location"=> {
              "lat"=>  35.58032,
              "lng"=> -122.2660670
            },
            "location_type"=> "ROOFTOP",
            "viewport"=> {
              "southwest"=> {
                "lat"=> 37.5653094,
                "lng"=> -122.2692146,
              },
              "northeast"=> {
                "lat"=> 37.5716046,
                "lng"=> -122.2629194
              }
            },
          },
        },
        {
          "types" => [ "street_address" ],
          "formatted_address" => address2,
          "address_components" => [],
          "geometry" => {
            "location"=> {
              "lat"=>  35.58032,
              "lng"=> -122.2660670
            },
            "location_type"=> "ROOFTOP",
            "viewport"=> {
              "southwest"=> {
                "lat"=> 37.5653094,
                "lng"=> -122.2692146,
              },
              "northeast"=> {
                "lat"=> 37.5716046,
                "lng"=> -122.2629194
              }
            },
          },
        }
      ]
    }
    result = Geokit::Geocoders::GoogleV3Geocoder.send :convert_json_to_geoloc, Yajl::Encoder.encode(input_data)
    assert result.success
    assert_equal 2, result.all.size
    assert_equal address1, result.all[0].full_address
    assert_equal address2, result.all[1].full_address
  end

  def test_extract_location_extracts_result_from_json
    data = Yajl::Parser.parse(GOOD_JSON)['results'][0]
    result = Geokit::Geocoders::GoogleV3Geocoder.send :extract_location, data
    assert_equal 'Foster City', result.city
    assert_equal 'CA', result.state
    assert_equal '94404', result.zip
    assert_equal 'United States', result.country
    assert_equal 'US', result.country_code
    assert_equal '1288 E Hillsdale Blvd', result.street_address
    assert_equal '1288 E Hillsdale Blvd, Foster City, CA 94404, USA', result.full_address
    assert_equal 37.5653094, result.suggested_bounds.sw.lat
    assert_equal -122.2692146, result.suggested_bounds.sw.lng
    assert_equal 37.5716046, result.suggested_bounds.ne.lat
    assert_equal -122.2629194, result.suggested_bounds.ne.lng
  end

  def test_extract_joins_street_address_with_no_number
    route_name = 'Foo'
    data =
      {
      "types" => [ "street_address" ],
      "formatted_address" => 'address1',
      "address_components" => [
        {'types' => ['route'], 'long_name' => route_name, 'short_name' => route_name}
      ],
      "geometry" => {
        "location"=> {
          "lat"=>  35.58032,
          "lng"=> -122.2660670
        },
        "location_type"=> "ROOFTOP",
        "viewport"=> {
          "southwest"=> {
            "lat"=> 37.5653094,
            "lng"=> -122.2692146,
          },
          "northeast"=> {
            "lat"=> 37.5716046,
            "lng"=> -122.2629194
          }
        },
      },
    }
    
    result = Geokit::Geocoders::GoogleV3Geocoder.send :extract_location, data
    assert_equal route_name, result.street_address
  end

  def test_extract_joins_street_address_with_no_route
    number = '358'
    data =
      {
      "types" => [ "street_address" ],
      "formatted_address" => 'address1',
      "address_components" => [
        {'types' => ['street_number'], 'long_name' => number, 'short_name' => number},
      ],
      "geometry" => {
        "location"=> {
          "lat"=>  35.58032,
          "lng"=> -122.2660670
        },
        "location_type"=> "ROOFTOP",
        "viewport"=> {
          "southwest"=> {
            "lat"=> 37.5653094,
            "lng"=> -122.2692146,
          },
          "northeast"=> {
            "lat"=> 37.5716046,
            "lng"=> -122.2629194
          }
        },
      },
    }

    result = Geokit::Geocoders::GoogleV3Geocoder.send :extract_location, data
    assert_equal number, result.street_address
  end

  def test_extract_joins_street_address_with_number_and_route
    route_name = 'Foo'
    number = '3854'
    data =
      {
      "types" => [ "street_address" ],
      "formatted_address" => 'address1',
      "address_components" => [
        {'types' => ['route'], 'long_name' => route_name, 'short_name' => route_name},
        {'types' => ['street_number'], 'long_name' => number, 'short_name' => number}
      ],
      "geometry" => {
        "location"=> {
          "lat"=>  35.58032,
          "lng"=> -122.2660670
        },
        "location_type"=> "ROOFTOP",
        "viewport"=> {
          "southwest"=> {
            "lat"=> 37.5653094,
            "lng"=> -122.2692146,
          },
          "northeast"=> {
            "lat"=> 37.5716046,
            "lng"=> -122.2629194
          }
        },
      },
    }

    result = Geokit::Geocoders::GoogleV3Geocoder.send :extract_location, data
    assert_equal number + ' ' + route_name, result.street_address
  end

end
