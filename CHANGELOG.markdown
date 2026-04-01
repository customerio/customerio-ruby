## Customerio 5.4.0 - June 13, 2025
### Changed
- Added `send_sms` to `APIClient` and `SendSMSRequest` to support sending transactional push notifications.

## Customerio 5.3.0 - December 8, 2023
### Changed
- The `identify` method has been updated to allow the customer ID to be specified separately from the attributes, using the `customer_id` attribute. This allows a person to be updated by identifying them by e.g.: their email address. Thanks to trwalzer, jrbeck and jeremyw for the original changes that this is based on.
- It is no longer possible to set the `customer_id` attribute on a person. This is a side-effect of the changes to the `identify` method.

## Customerio 5.2.0 - December 8, 2023
### Changed
- The `identify` method will now automatically use the `cio_id` attribute as the customer ID when calling the track service. This allows a customer to be updated using `identify` to modify the `id` and `email` attributes.

## Customerio 5.1.0 - May 5, 2023
### Added
- Added `send_push` to `APIClient` and `SendPushRequest` to support sending transactional push notifications.

## Customerio 4.3.1 - January 5, 2023
### Added
- Added the `disable_css_preprocessing` and `language` optional fields to send request

## Customerio 4.3.0 - April 26, 2022
### Added
- Support for [anonymous invite events](https://customer.io/docs/anonymous-invite-emails/) by setting `anonymous_id` to `nil`. 

## Customerio 4.1.0 - Sep 27, 2021
### Added
- Added support for [merge customers](https://customer.io/docs/api/#operation/merge) API

## Customerio 4.0.1 - July 13, 2021
### Changed
- Update addressable gem dependency to v2.8.0

## Customerio 4.0.0 - July 6, 2021
### Removed
- The `anonymous_track` method.

### Added
- The `track_anonymous` method replaces `anonymous_track`. This method requires an `anonymous_id` parameter and will no longer trigger campaigns. If you previously used anonymous events to trigger campaigns, you can still do so [directly through the API](https://customer.io/docs/api/#operation/trackAnonymous). We now refer to anonymous events that trigger campaigns as ["invite events"](https://customer.io/docs/anonymous-events/#anonymous-or-invite). 

## Customerio 3.1.0 - March 25, 2021
### Added
- Support for EU region

### Removed
### Changed
- `Customerio::Client` and `CustomerIO::APIClient`  have a new parameter `region` that can be set to either `Customerio::Regions::EU` or `Customerio::Regions::US` (defaults to `Customerio::Regions::US`)

## Customerio 3.0.0 - Dec 2, 2020

### Added
- Support for the Transactional API

### Removed
- `add_to_segment` and `remove_from_segment` methods
- Support for non-JSON data

### Changed
- IDs in the URLs are now escaped.
- Improved validations for data that's passed in.
- Earlier, if you passed in an event name without a customer ID to the `track` method, we would create an anonymous event. That is now removed. To create an anonymous event, use the `anonymous_track` method.


## Customerio 3.0.0 - Dec 2, 2020

### Added
- Support for the Transactional API

### Removed
- `add_to_segment` and `remove_from_segment` methods
- Support for non-JSON data

### Changed
- IDs in the URLs are now escaped.
- Improved validations for data that's passed in.
- Earlier, if you passed in an event name without a customer ID to the `track` method, we would create an anonymous event. That is now removed. To create an anonymous event, use the `anonymous_track` method.

## Customerio 2.2.1 - Mar 23, 2020

- Add license to gemspec [#55](https://github.com/customerio/customerio-ruby/pull/55)
- Bubble up error message [#51](https://github.com/customerio/customerio-ruby/pull/51)

## Customerio 2.2.0 - Oct 18, 2018

Add support for manual segments [#52](https://github.com/customerio/customerio-ruby/pull/52)

## Customerio 2.1.0 - May 22, 2018

Added support for the suppress / unsuppress methods [#49](https://github.com/customerio/customerio-ruby/pull/49)

## Customerio 2.0.0 - Apr 10, 2018

With this release we have dropped the support for ruby 1.8.7.

- Support new add and remove device endpoints for push notifications [#47](https://github.com/customerio/customerio-ruby/pull/47)

## Customerio 1.0.0 - Mar 15, 2016

There is a slight breaking change in this release. If you are depending on the HTTP response object included in the InvalidResponse exception (introduced in 0.6.1), note that it is now a `Net::HTTPBadRequest`.

- Remove HTTParty dependency, use Net::HTTP instead. [#42](https://github.com/customerio/customerio-ruby/pull/42)

- Update test suite to use webmock, to increase confidence that we're not changing our HTTP requests [#41](https://github.com/customerio/customerio-ruby/pull/41)

## Customerio 0.7.0 - Mar 2, 2016

- Add new method for tracking anonymous events: `anonymous_track`. See README for more details. Many thanks to @sdawson for this contribution! [#36](https://github.com/customerio/customerio-ruby/pull/36)

- Use JSON encoding by default. [#37](https://github.com/customerio/customerio-ruby/pull/37)

  If you want to stick with form-encoding for your integration, you must add `:json => false` to your Customerio::Client initializer. Like this:

  ```ruby
  customerio = Customerio::Client.new("YOUR SITE ID", "YOUR API SECRET KEY", :json => false)
  ```

## Customerio 0.6.1 - Oct 8, 2015

- Include HTTP response as an attribute on the InvalidResponse exception to help with debugging failed API requests. For example:

  ```ruby
  begin
    $customerio.track(1, 'event', { :test => 'testing' })
  rescue => e
    puts e.message
    puts e.response.status
    puts e.response.body
  end
  ```

## Customerio 0.6.0 - Oct 6, 2015

Deprecation warning: we are going to switch to JSON encoding by default for the next release. The current default is form-encoding. This will probably not affect you, unless you rely on how form-encoding arrays work.

If you want to stick with form-encoding for your integration, you must add `:json => false` to your Customerio::Client initializer. Like this:

```ruby
customerio = Customerio::Client.new("YOUR SITE ID", "YOUR API SECRET KEY", :json => false)
```

Other fixes and improvements, with many thanks to the community contributors:

- Added HTTP timeout of 10 seconds (@stayhero)
- Added JSON support for events (@kemper)
- Convert attribute keys to symbols (@joshnabbott)

## Customerio 0.5.0 - Mar 28, 2014

- Added flag to send body encoded as JSON, rather than the default form encoding.

## Customerio 0.5.0 - Apr 8, 2013

- Removed deprecated methods around using a customer object. All calls simply take a hash of attributes now.
- Added ability to set a timestamp on a tracked event. Useful for backfilling past events.

## Customerio 0.4.1 - Feb 18, 2013

- Bug fixes related to the 4.0 change.

## Customerio 0.4.0 - Feb 18, 2013

- Added support for deleting customers.

## Customerio 0.3.0 - Dec 28, 2012

- Now raise an error if an API call doesn't respond with a 200 response code
- Removed dependency on ActiveSupport

## Customerio 0.2.0 - Nov 21, 2012

- Allow raw hashes to be passed into `identify` and `track` methods rather than a customer object.
- Passing a customer object has been depreciated.
- Customizing ids with `Customerio::Client.id` block is deprecated.

## Customerio 0.1.0 - Nov 15, 2012

- Allow tracking of anonymous events.

## Customerio 0.0.3 - Nov 5, 2012

- Bump httparty dependency to the latest version.

## Customerio 0.0.2 - May 22, 2012

- First release.
