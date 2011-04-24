# geocoder_plus

This gem has two additional geocoders for geokit gem, Yahoo! PlaceFinder and Google V3.
Google V3 code is taken from https://github.com/tello/google-v3-geocoder.

Support for query caching is added by using [api_cache](https:/github.com/mloughran/api_cache).

## Quick Start

    # Install
    gem install geocoder_plus
    gem install api_cache
    gem install moneta

		# Configuration
		Add following configuration to your geokit config file:
	      require 'api_cache'
			  require 'moneta'
			  require 'moneta/memcache'
			  Geokit::Geocoders::api_cache         = 604800
			  Geokit::Geocoders::api_cache_valid   = :forever
			  Geokit::Geocoders::api_cache_timeout = 5
			  APICache.store = Moneta::Memcache.new(:server => localhost:11211, :namespace => 'geokit')
		
## Contributing

There is a Gemfile to make running the specs easy:

    bundle install
    bundle exec rake

Code, write specs, send pull request, easy as pie. Thanks!

## Copyright

Copyright (c) 2011 Fajar A B. See LICENSE for details.