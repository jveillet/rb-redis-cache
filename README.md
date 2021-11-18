# rb-redis-cache

[![Build Status](https://github.com/jveillet/rb-redis-cache/workflows/CI/badge.svg)](https://github.com/rb-redis-cache/actions)

A simple framework-agnostic cache with Redis.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rb-redis-cache'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rb-redis-cache
```

## Usage

### Connection

You can connect to Redis by configuring the Cache class:

```ruby
require 'cache'

Cache.config(url: REDIS_URL)
```

### Storing objects

You can cache simple data structures that can be serialized to JSON.

```ruby
Cache.write('my_key', 'my_value')
```

```ruby
my_hash = {a: 'a', b: 'b', c: [{ d: 'd' }]}
Cache.write('my_key', my_hash)
```

Optionaly, you can set an expiry time in seconds fot the key.

```ruby
Cache.write('my_key', 'my_value', expires_in: 60)
```

### Retrieving objects

You can cache pretty much anything as it is serialized before inserting.

```ruby
Cache.read('my_key')
=> 'my_value'
```

### Increment a counter

Increments the number stored at key by one.

```ruby
Cache.increment('my_key_inc')
=> 1
```

```ruby
Cache.increment('my_key_inc')
=> 2
```

### Rails-style fetching

You can fetch a key from the cache, if there is an existing value for a given key, then this value is returned.
If there is no value for the given key, and a block parameter has been passed, then the result will be cached and returned.

```ruby
Cache.fetch('my_key', expires_in: 60) do
  block_method_calculation
end
=> 'my_value'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jveillet/rb-redis-cache/issues.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
