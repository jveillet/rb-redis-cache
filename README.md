# rb-redis-cache

[![Build Status](https://github.com/jveillet/rb-redis-cache/workflows/CI/badge.svg)](https://github.com/rb-redis-cache/actions)

A simple framework-agnostic cache with Redis.

⚠️ This gem is still under development, the api is not stable and there might be breaking changes until we reach v1.0.

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

You can connect to Redis by configuring the `RedisCache::Store` class:

```ruby
require 'redis_cache'

cache = RedisCache::Store.new(url: REDIS_URL)
```

Alternatively, you can pass options to the `Store` instance:

```ruby
require 'redis_cache'

cache = RedisCache::Store.new(url: REDIS_URL, connect_timeout: 10)
```

Defaults are defined in [lib/redis_cache.rb](lib/redis_cache.rb#L17) and can be overrided.

### Storing objects

You can store data structures that can be serialized to JSON.

```ruby
cache.write('my_key', 'my_value')
```

```ruby
my_hash = {a: 'a', b: 'b', c: [{ d: 'd' }]}
cache.write('my_key', my_hash)
```

Optionaly, you can set an expiry time in seconds fot the key.

```ruby
cache.write('my_key', 'my_value', expires_in: 60)
```

### Retrieving objects

```ruby
cache.read('my_key')
=> 'my_value'
```

### Incrementing a counter

Increments the number stored at key by increment.

```ruby
cache.increment('my_key_inc')
=> 1
cache.increment('my_key_inc')
=> 2
```

### Decrementing a counter

Decrements the number stored at key by decrement.

```ruby
cache.increment('my_key_inc')
=> 1
cache.increment('my_key_inc')
=> 2
cache.decrement('my_key_inc')
=> 1
```

### Rails-style fetching

You can fetch a key from the cache, if there is an existing value for a given key, then this value is returned.
If there is no value for the given key, and a block parameter has been passed, then the result will be cached and returned.

```ruby
cache.fetch('my_key', expires_in: 60) do
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
