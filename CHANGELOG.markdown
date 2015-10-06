## Customerio 0.6.0 - Oct 6, 2015 ##

Deprecation warning: we are going to switch to JSON encoding by default for the next release. The current default is form-encoding. This will probably not affect you, unless you rely on how form-encoding arrays work.

If you want to stick with form-encoding for your integration, you must add `:json => false` to your Customerio::Client initializer. Like this:

```ruby
customerio = Customerio::Client.new("YOUR SITE ID", "YOUR API SECRET KEY", :json => false)
```

Other fixes and improvements, with many thanks to the community contributors:

* Added HTTP timeout of 10 seconds (@stayhero)
* Added JSON support for events (@kemper)
* Convert attribute keys to symbols (@joshnabbott)

## Customerio 0.5.0 - Mar 28, 2014 ##

* Added flag to send body encoded as JSON, rather than the default form encoding.

## Customerio 0.5.0 - Apr 8, 2013 ##

* Removed deprecated methods around using a customer object. All calls simply take a hash of attributes now.
* Added ability to set a timestamp on a tracked event.  Useful for backfilling past events.

## Customerio 0.4.1 - Feb 18, 2013 ##

* Bug fixes related to the 4.0 change.

## Customerio 0.4.0 - Feb 18, 2013 ##

* Added support for deleting customers.

## Customerio 0.3.0 - Dec 28, 2012 ##

* Now raise an error if an API call doesn't respond with a 200 response code
* Removed dependency on ActiveSupport

## Customerio 0.2.0 - Nov 21, 2012 ##

* Allow raw hashes to be passed into `identify` and `track` methods rather than a customer object.
* Passing a customer object has been depreciated.
* Customizing ids with `Customerio::Client.id` block is deprecated.

## Customerio 0.1.0 - Nov 15, 2012 ##

* Allow tracking of anonymous events.

## Customerio 0.0.3 - Nov 5, 2012 ## 

* Bump httparty dependency to the latest version.

## Customerio 0.0.2 - May 22, 2012 ##

* First release.
