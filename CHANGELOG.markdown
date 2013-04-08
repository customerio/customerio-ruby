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
