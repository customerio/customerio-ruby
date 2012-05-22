# Customerio

A Customer.io API client in Ruby using HTTParty.

## Installation

Add this line to your application's Gemfile:

    gem 'customerio'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install customerio

## Usage

Create an instance of the client with your customer.io credentials
which can be found in your [customer.io settings](https://app.customer.io/settings).

If you're using Rails, create an initializer `config/initializers/customerio.rb`:

    $customerio = Customerio.new("YOUR SITE ID", "YOUR API SECRET KEY")

### Identify logged in customers

Tracking data of logged in customers is a key part of Customer.io. In order to
send triggered emails, we must know the email address of the customer.  You can
also specify any number of customer attributes which help tailor Customer.io to your
business.

Attributes you specify are useful in several ways:

* As customer variables in your triggered emails.  For instance, if you specify
the customer's name, you can personalize the triggered email by using it in the
subject or body.

* As a way to filter who should receive a triggered email.  For instance,
if you pass along the current subscription plan for your customers, you can
set up triggers which are only sent to customers who have subscribed to a
particular plan.

    # Arguments
    # customer (required)   - a customer object which responds to a few key
    #                         methods about the customer:
    # 
    #                         customer.id - a unique identifier for the customer
    #                         email       - the customer's current email address
    #                         created_at  - a timestamp which represents when the
    #                                       customer was first created.
    # 
    # attributes (optional) - a hash of information about the customer. You can pass any
    #                         information that would be useful in your triggers.

    $customerio.identify(customer, first_name: "Bob", plan: "basic")

### Tracking a custom event

Now that you're identifying your customers with Customer.io, you can now send events like
"purchased" or "watchedIntroVideo".  These allow you to more specifically target your users
with automated emails, and track conversions when you're sending automated emails to
encourage your customers to perform an action.

    # Arguments
    # customer (required)   - the customer who you want to associate with the event.
    # name (required)       - the name of the event you want to track.
    # attributes (optional) - any related information you'd like to attach to this
    #                         event. These attributes can be used in your triggers to control who should
    #                         receive the triggered email. You can set any number of data values.

    $customerio.track(user, "purchase", type: "socks", price: "13.99")

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request