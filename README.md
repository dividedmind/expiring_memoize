# ExpiringMemoize

Memoize a method result, refetching after a time to live has elapsed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'expiring_memoize'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install expiring_memoize

## Usage

```ruby
class PriceFetcher
  def current_price
    puts 'fetching'
    rand # say it's an expensive operation here
  end

  extend ExpiringMemoize
  memoize :current_price, ttl: Float::INFINITY
end

fetcher = PriceFetcher.new

puts fetcher.current_price # fetched
puts fetcher.current_price # uses cached value
sleep 5
puts fetcher.current_price # fetched again

# works multi-threaded too;
# code below fetches only once

fetcher = PriceFetcher.new
5.times.map do
  Thread.new do
    sleep rand
    puts fetcher.current_price
  end
end.join
```

## Features

- Thread safe.
  If many threads try to get the value and it's found to be stale, they race to
  refetch and only one of them does.
- Exception safe.
  If the fetch raises an exception it'll bubble up to the caller. Since the
  value will still be stale, next query will retry the fetch.
- Time travel safe.
  Uses `Process.clock_gettime` to provide a monotonic clock. Time adjustment
  events, eg. sleep, ntpdate etc. do not affect the TTL calculation.

## Implementation details

Per-object data is stored in `@_expiring_memoize_data` instance variable as a
hash, to avoid polluting the ivar namespace. The memoized method is replaced
and the original is held in the closure of the replacement.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Known limitations

- Only nullary instance methods are supported.
- Won't work on platforms where `Process.clock_gettime` is not supported, or
  where it does not support `CLOCK_MONOTONIC_COARSE`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dividedmind/expiring_memoize.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
