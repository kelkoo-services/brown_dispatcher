# BrownDispatcher

This gem helps you creating a distributed webservice. Different
individual services will be able to register into a shared redis
database, and every request will be dispatched to the right webservice
(depending on the prefix of the request path)

## Installation

Add this line to your application's Gemfile:

    gem 'brown_dispatcher'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install brown_dispatcher

## Usage

In config/application.rb

    config.middleware.use "BrownDispatcher::Interceptor"

In config/initializers/brown\_dispatcher.rb

    BrownDispatcher::Service.register("http://foobar.io", "/foo", "/bar", "/baz")

And this is it!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

