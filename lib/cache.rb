# frozen_string_literal: true

require 'cache/version'
require 'logger'
require 'connection_pool'
require 'redis'
require 'mock_redis'
require 'json'

##
# Redis Cache library.
# This library can read and write data into Redis via the redis-rb gem.
#
module Cache
  class << self
    ##
    # Configuration method.
    #
    # @param url [String] the url of the Redis instance.
    # @param timeout [Integer] the Redis timeout value.
    # @param reconnect_attempts [Integer] the number of reconnect attempts of Redis.
    # @param reconnect_delay [Integer] the delay between reconnect attemps of Redis.
    # @param reconnect_delay_max [Integer] the maximum delay between reconnect attempts of Redis.
    # @param size [Integer] the pool size for the Redis connection.
    #
    def config(url: nil, timeout: 1, reconnect_attempts: 2, reconnect_delay: 1, reconnect_delay_max: 2, size: 5)
      @config ||= {
        url: url,
        timeout: timeout,
        reconnect_attempts: reconnect_attempts,
        reconnect_delay: reconnect_delay,
        reconnect_delay_max: reconnect_delay_max,
        size: size
      }
    end

    ##
    # Reads a key from the cache.
    #
    # @param key [String] the cache key to retrieve.
    # @return [JSON, String] the unencrypted value from the cache.
    #
    def read(key)
      response = redis.with do |conn|
        conn.get(key)
      end

      if response.nil?
        logger.info("cache.miss=1 cache.key=#{key}")
        return nil
      end

      deserialized_value = deserialize(response)
      logger.info("cache.hit=1 cache.key=#{key} cache.value=#{deserialized_value}")

      deserialized_value
    end

    ##
    # Writes a string value into the cache.
    #
    # @param key [String] the cache key to write.
    # @param value [String] the string valeu to write.
    # @param options [Hash] the options dictionnary containing for example the expiry data.
    # @return [void]
    #
    def write(key, value, options = {})
      redis.with do |conn|
        if options[:expires_in]
          logger.info("cache.write=1 cache.key=#{key}, cache.value=#{value} cache.expires_in=#{options[:expires_in]}")
          conn.setex(key, options[:expires_in], serialize(value))
        else
          logger.info("cache.write=1 cache.key=#{key}, cache.value=#{value}")
          conn.set(key, serialize(value))
        end
      end
    end

    ##
    # Fetch from the cache.
    # This method is a combination of reading and writing into the cache.
    # If the key exists, it's fetched, otherwise it executes the block method,
    # and cache the result before returning it.
    #
    # @param key [String] the cache key namespace.
    # @param options [Hash] a dictionnary containing options for the cache, like expiry settings.
    # @param value [Block] a block method to execute, and cache the result.
    # @return [Object] the result of the cache, or the computed result of the block parameter.
    #
    def fetch(key, options = {}, &value)
      cache = read(key)
      return cache if exists?(key) && !options[:force]

      block = yield value if value

      return unless block && !block.empty?

      write(key, block, options)

      block
    end

    ##
    # Deletes keys in the cache
    #
    # @param keys [Array] the list of keys to delete.
    # @return [Integer] a value superior to 0 if the delete succeded.
    #
    def delete(*keys)
      redis.with do |conn|
        conn.del(*keys)
      end
    end

    ##
    # Checks if a key exists into the cache.
    #
    # @param key [String] the key name to search in the cache.
    #
    def exists?(key)
      redis.with do |conn|
        conn.exists?(key)
      end
    end

    private

    def serialize(value)
      JSON.generate(value)
    end

    def deserialize(value)
      JSON.parse(value, symbolize_names: true)
    end

    def redis
      @redis ||= create_connection(config)
    end

    def create_connection(config = {})
      raise 'A Redis URL is not set. Please use the `url` part of the config.' unless config[:url] || test?

      ConnectionPool.new(timeout: config[:timeout], size: config[:size]) do
        if test?
          MockRedis.new
        else
          Redis.new(config)
        end
      end
    end

    def test?
      ENV['ENV'].to_s == 'test'
    end

    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
