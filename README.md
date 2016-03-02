# Customerio

A ruby client for the [Customer.io](http://customer.io) [event API](http://customer.io/docs/api/overview.html).

[![Build Status](https://secure.travis-ci.org/customerio/customerio-ruby.png?branch=master)](http://travis-ci.org/customerio/customerio-ruby)
[![Code Climate](https://codeclimate.com/github/customerio/customerio-ruby/badges/gpa.svg)](https://codeclimate.com/github/customerio/customerio-ruby)

## Installation

Add this line to your application's Gemfile:

    gem 'customerio'

And then execute:

    $ bundle

Or install it yourself:

    $ gem install customerio

## Usage

### Before we get started: API client vs. JavaScript snippet

It's helpful to know that everything below can also be accomplished
through the [Customer.io JavaScript snippet](http://customer.io/docs/basic-integration.html).

In many cases, using the JavaScript snippet will be easier to integrate with
your app, but there are several reasons why using the API client is useful:

* You're not planning on triggering emails based on how customers interact with
  your website (e.g. users who haven't visited the site in X days)
* You're using the javascript snippet, but have a few events you'd like to
  send from your backend system.  They will work well together!
* You'd rather not have another javascript snippet slowing down your frontend.
  Our snippet is asynchronous (doesn't affect initial page load) and very small, but we understand.

In the end, the decision on whether or not to use the API client or
the JavaScript snippet should be based on what works best for you.
You'll be able to integrate **fully** with [Customer.io](http://customer.io) with either approach.

### Setup

Create an instance of the client with your [customer.io](http://customer.io) credentials
which can be found on the [customer.io integration screen](https://manage.customer.io/integration).

If you're using Rails, create an initializer `config/initializers/customerio.rb`:

```ruby
$customerio = Customerio::Client.new("YOUR SITE ID", "YOUR API SECRET KEY")
```

If you'd like to send complex data to associate to a user as json, pass a json option:

```ruby
customerio = Customerio::Client.new("YOUR SITE ID", "YOUR API SECRET KEY", :json => true)
```

### Identify logged in customers

Tracking data of logged in customers is a key part of [Customer.io](http://customer.io). In order to
send triggered emails, we must know the email address of the customer.  You can
also specify any number of customer attributes which help tailor [Customer.io](http://customer.io) to your
business.

Attributes you specify are useful in several ways:

* As customer variables in your triggered emails.  For instance, if you specify
the customer's name, you can personalize the triggered email by using it in the
subject or body.

* As a way to filter who should receive a triggered email.  For instance,
if you pass along the current subscription plan (free / basic / premium) for your customers, you can
set up triggers which are only sent to customers who have subscribed to a
particular plan (e.g. "premium").

You'll want to indentify your customers when they sign up for your app and any time their
key information changes. This keeps [Customer.io](http://customer.io) up to date with your customer information.

```ruby
# Arguments
# attributes (required) - a hash of information about the customer. You can pass any
#                         information that would be useful in your triggers. You 
#                         must at least pass in an id, email, and created_at timestamp.

$customerio.identify(
  :id => 5,
  :email => "bob@example.com",
  :created_at => customer.created_at.to_i,
  :first_name => "Bob",
  :plan => "basic"
)
```

### Deleting customers

Deleting a customer will remove them, and all their information from
Customer.io.  Note: if you're still sending data to Customer.io via
other means (such as the javascript snippet), the customer could be
recreated.

```ruby
# Arguments
# customer_id (required) - a unique identifier for the customer.  This
#                          should be the same id you'd pass into the
#                          `identify` command above.

$customerio.delete(5)
```

### Tracking a custom event

Now that you're identifying your customers with [Customer.io](http://customer.io), you can now send events like
"purchased" or "watchedIntroVideo".  These allow you to more specifically target your users
with automated emails, and track conversions when you're sending automated emails to
encourage your customers to perform an action.

```ruby
# Arguments
# customer_id (required) - the id of the customer who you want to associate with the event.
# name (required)        - the name of the event you want to track.
# attributes (optional)  - any related information you'd like to attach to this
#                          event. These attributes can be used in your triggers to control who should
#                          receive the triggered email. You can set any number of data values.

$customerio.track(5, "purchase", :type => "socks", :price => "13.99")
```

**Note:** If you'd like to track events which occurred in the past, you can include a `timestamp` attribute
(in seconds since the epoch), and we'll use that as the date the event occurred.

```ruby
$customerio.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => 1365436200)
```

### Tracking anonymous events

You can also send anonymous events, for situations where you don't yet have a customer record but still want to trigger a campaign:

```ruby
$customerio.anonymous_track("help_enquiry", :recipient => 'user@example.com')
```

Use the `recipient` attribute to specify the email address to send the messages to. [See our documentation on how to use anonymous events for more details](https://customer.io/docs/invitation-emails.html).

## Contributing

1. Fork it
2. Clone your fork (`git clone git@github.com:MY_USERNAME/customerio-ruby.git && cd customerio-ruby`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
