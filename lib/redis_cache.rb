# frozen_string_literal: true

require 'redis_cache/version'
require 'redis_cache/errors'
require 'logger'
require 'connection_pool'
require 'redis'
require 'json'

module RedisCache
  ##
  # Redis Cache library.
  # This library can read and write data into Redis via the redis-rb gem.
  #
  class Store
    class << self
      DEFAULT_REDIS_OPTIONS = {
        connect_timeout: 20,
        read_timeout: 1,
        write_timeout: 1,
        timeout: 1,
        reconnect_attempts: 0,
        reconnect_delay: 1,
        reconnect_delay_max: 2,
        size: 3
      }.freeze

      ##
      # Build the redis connection.
      #
      # @param url [String] URL of the redis instance.
      # @param options [Hash] options list for redis configuration.
      #
      def build_redis(url: nil, **options)
        redis_options = DEFAULT_REDIS_OPTIONS.merge(options.merge(url: url))
        create_connection(**redis_options)
      end

      ##
      # Creates the redis connection pool.
      #
      # @param config [Hash] list of configuration options.
      # @return [Object] the redis connection instance.
      #
      def create_connection(**options)
        raise CacheConnectionError unless options[:url] || test?

        ConnectionPool.new(timeout: options[:timeout], size: options[:size]) do
          if test?
            require 'mock_redis'
            MockRedis.new
          else
            Redis.new(options)
          end
        end
      end

      private

      def test?
        ENV['ENV'].to_s == 'test'
      end
    end

    attr_reader :options

    def initialize(**options)
      @options = options
    end

    ##
    # The redis connection.
    #
    # @return [Object] the redis connection instance.
    #
    def redis
      @redis ||= self.class.build_redis(**options)
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
    # Increments the number stored at key by increment.
    #
    # @param key [String] the cache key namespace.
    # @param options [Hash] a dictionnary containing options for the cache, like expiry settings.
    # @return [Integer] the total increment value.
    #
    def increment(key, amount = 1, options = nil)
      redis.with do |conn|
        conn.incrby(key, amount).tap do
          logger.info("cache.write=1 cache.key=#{key}, cache.value=#{amount}")
          expire(conn, key, options)
        end
      end
    end

    ##
    # Decrements the number stored at key by decrement.
    #
    # @param key [String] the cache key namespace.
    # @param options [Hash] a dictionnary containing options for the cache, like expiry settings.
    # @return [Integer] the total increment value.
    #
    def decrement(key, amount = 1, options = nil)
      redis.with do |conn|
        conn.decrby(key, amount).tap do
          logger.info("cache.write=1 cache.key=#{key}, cache.value=#{amount}")
          expire(conn, key, options)
        end
      end
    end

    ##
    # Sets expiration time on a key, a posteriori.
    #
    # @param client [Object] a redis connection client instance.
    # @param key [String] the cache key namespace.
    # @param options [Hash] a dictionnary containing options for the cache, like expiry settings.
    #
    def expire(client, key, options)
      return unless options && options[:expires_in] && client.ttl(key).negative?

      logger.info("cache.write=1 cache.key=#{key}, cache.expiry=#{options[:expires_in].to_i}")
      client.expire key, options[:expires_in].to_i
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

    alias_method :exist?, :exists?

    private

    ##
    # Serialize value to JSON.
    #
    # @param value [String] the value to be serialized to JSON.
    # @return [JSON] the JSON value.
    #
    def serialize(value)
      JSON.generate(value)
    end

    ##
    # Deserialize value to JSON.
    #
    # @param value [String] the value to be deserialized from JSON.
    # @return [mixed] the deserialized value.
    #
    def deserialize(value)
      JSON.parse(value, symbolize_names: true)
    end

    ##
    # Logger instance.
    #
    # @return [Object] the logger instance.
    #
    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
