require 'helper'

class TestYahooPlaceFinderGeocoder < Test::Unit::TestCase
    
  # default is true
  MOCK = false
  
  US_FULL_ADDRESS=<<-EOF.strip
    {"query":{"count":1,"created":"2011-04-03T01:20:47Z","lang":"en-US","results":{"Result":{"quality":"87","latitude":"37.792418","longitude":"-122.393913","offsetlat":"37.792332","offsetlon":"-122.394027","radius":"500","name":null,"line1":"100 Spear St","line2":"San Francisco, CA  94105-1578","line3":null,"line4":"United States","house":"100","street":"Spear St","xstreet":null,"unittype":null,"unit":null,"postal":"94105-1578","neighborhood":null,"city":"San Francisco","county":"San Francisco County","state":"California","country":"United States","countrycode":"US","statecode":"CA","countycode":null,"uzip":"94105","hash":"0FA06819B5F53E75","woeid":"12797156","woetype":"11"}}}}
  EOF
  
  US_CITY=<<-EOF.strip
    {"query":{"count":1,"created":"2011-04-04T15:10:42Z","lang":"en-US","results":{"Result":{"quality":"40","latitude":"37.777125","longitude":"-122.419644","offsetlat":"37.777125","offsetlon":"-122.419644","radius":"10700","name":null,"line1":null,"line2":"San Francisco, CA","line3":null,"line4":"United States","house":null,"street":null,"xstreet":null,"unittype":null,"unit":null,"postal":null,"neighborhood":null,"city":"San Francisco","county":"San Francisco County","state":"California","country":"United States","countrycode":"US","statecode":"CA","countycode":null,"uzip":"94102","hash":null,"woeid":"2487956","woetype":"7"}}}}
  EOF
  
  context "given a US full address" do
    setup do
      full_address = '100 Spear St, San Francisco, CA, 94105-1522, US'
      if MOCK
        response = Typhoeus::Response.new(@success_response.merge(:body => US_FULL_ADDRESS))
        Geokit::Geocoders::YahooPlaceFinderGeocoder.expects(:make_request).with('get', :params => {:q => "select * from geo.placefinder where text='#{full_address}'", :format => 'json'}).returns(response)
      end
      @pf = Geokit::Geocoders::YahooPlaceFinderGeocoder.geocode(full_address)
    end
    
    should "return correct geo location" do
      do_full_address_assertions(@pf)
      assert @pf.is_us?
    end
    
    should "have 'address' accuracy" do
      assert_equal 'address', @pf.precision
    end    
  end
  
  context "given a US city" do
    setup do
      city = 'San Francisco, CA'
      if MOCK
        response = Typhoeus::Response.new(@success_response.merge(:body => US_CITY))
        Geokit::Geocoders::YahooPlaceFinderGeocoder.expects(:make_request).with('get', :params => {:q => "select * from geo.placefinder where text='#{city}'", :format => 'json'}).returns(response)
      end
      @pf = Geokit::Geocoders::YahooPlaceFinderGeocoder.geocode(city)
    end
    
    should "return correct geo location" do
      do_city_assertions(@pf)
      assert @pf.is_us?
    end
    
    should "have 'address' accuracy" do
      assert_equal 'city', @pf.precision
    end    
  end
  
  context "given a non-US street" do
    setup do
      full_address = 'Jalan Gandaria Tengah, Jakarta 12140, Indonesia'
      if MOCK
        response = Typhoeus::Response.new(@success_response.merge(:body => US_FULL_ADDRESS))
        Geokit::Geocoders::YahooPlaceFinderGeocoder.expects(:make_request).with('get', :params => {:q => "select * from geo.placefinder where text='#{full_address}'", :format => 'json'}).returns(response)
      end
      @pf = Geokit::Geocoders::YahooPlaceFinderGeocoder.geocode(full_address)
    end
    
    should "return correct geo location" do
      do_non_us_street_assertions(@pf)
    end
    
    should "have 'address' accuracy" do
      assert_equal 'street', @pf.precision
    end    
  end
  
  context "given a non-US city" do
    setup do
      city = 'Jakarta, Indonesia'
      if MOCK
        response = Typhoeus::Response.new(@success_response.merge(:body => US_CITY))
        Geokit::Geocoders::YahooPlaceFinderGeocoder.expects(:make_request).with('get', :params => {:q => "select * from geo.placefinder where text='#{city}'", :format => 'json'}).returns(response)
      end
      @pf = Geokit::Geocoders::YahooPlaceFinderGeocoder.geocode(city)
    end
    
    should "return correct geo location" do
      do_non_us_city_assertions(@pf)
    end
    
    should "have 'address' accuracy" do
      assert_equal 'city', @pf.precision
    end    
  end
  
  
  
  
  
  private
  
  # next two methods do the assertions for both address-level and city-level lookups
  def do_full_address_assertions(resp)
    assert_equal "CA", resp.state
    assert_equal "San Francisco", resp.city
    assert_equal "37.792418,-122.393913", resp.ll
    assert resp.is_us?
    assert_equal "100 Spear St, San Francisco, CA, 94105-1578, US", resp.full_address
    assert_equal "Yahoo! PlaceFinder", resp.provider
  end
  
  def do_city_assertions(resp)
    assert_equal "CA", resp.state
    assert_equal "San Francisco", resp.city 
    assert_equal "37.777125,-122.419644", resp.ll
    assert resp.is_us?
    assert_equal "San Francisco, CA, US", resp.full_address 
    assert_nil resp.street_address
    assert_equal "Yahoo! PlaceFinder", resp.provider
  end
  
  def do_non_us_street_assertions(resp)
    assert_equal "D K I Jakarta", resp.state
    assert_equal "Kebayoran Baru", resp.city
    assert_equal "-6.246406,106.789707", resp.ll
    assert_equal false, resp.is_us?
    assert_equal "Jalan Gandaria Tengah 3, Kebayoran Baru, D K I Jakarta, 12140, ID", resp.full_address
    assert_equal "Yahoo! PlaceFinder", resp.provider
  end
  
  def do_non_us_city_assertions(resp)
    assert_equal "DKI Jakarta", resp.state
    assert_equal "Jakarta", resp.city 
    assert_equal "-6.17144,106.82782", resp.ll
    assert_equal false, resp.is_us?
    assert_equal "Jakarta, DKI Jakarta, ID", resp.full_address 
    assert_nil resp.street_address
    assert_equal "Yahoo! PlaceFinder", resp.provider
  end

end