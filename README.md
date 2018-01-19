# ActiveRecord-ForbidImplicitCheckout

This gem allows a `Thread` to prevent itself from checking out out an ActiveRecord connection. This can be useful
in preventing your application from accidentally checking out more connections than the database can handle.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-forbid_implicit_checkout'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-forbid_implicit_checkout

## Usage

```ruby
Thread.new do
  ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
  # Code that doesn't require ActiveRecord
end
```

## Why
Consider the following initially:

```ruby
class Foo
  def self.download(id)
    Net::HTTP.get(URI("http://example.com/products/#{URI.encode(id)}"))
  end
end

Class Downloader
def download_all(ids)
  threads = ids.map do |id|
    Thread.new do
      ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!
      Foo.download
    end
  end
  threads.each(&:join)
end

Downloader.download_all([1,2,3,4,5])
```

The developer initially designed this parallel downloading to not be dependent on the database, so the developer feels confident in running
many parallel processes of `Downloader.download_all`.

However, `Foo.download` might be subject to change.

```ruby
class SomeModel < ApplicationRecord
  # ...
end

class Foo
  def self.download(id)
    id = SomeModel.find(id).alias_id
    Net::HTTP.get(URI("http://example.com/products/#{URI.encode(id)}"))
  end
end
```

After this modification to `Foo.download`, each thread will checkout a new connection to the database. Which could
overwhelm the database if there are many parallel processes executing `Downloader.download_all`. While this violates,
the initial assumption about `Downloader.download_all` using the database, it would have been useful to have a safeguard to prevent
this situation from occurring.

The error generated by setting `ActiveRecord::Base.forbid_implicit_connection_checkout_for_thread!` could have detected
 this situation during testing which should have failed with `ActiveRecord::ImplicitConnectionForbiddenError`. In the
 worst case, the production code running this would have failed with `ActiveRecord::ImplicitConnectionForbiddenError`,
 but it would have prevented the database from being overwhelmed and have protected the rest of the application.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org)
.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/activerecord-forbid_implicit_checkout.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

