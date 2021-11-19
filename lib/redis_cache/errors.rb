# frozen_string_literal: true

module RedisCache
  # Raised when the Redis connection cannot be established.
  class CacheConnectionError < StandardError
    def initialize(message = 'A Redis URL is not set. Please use the `url` part of the config.')
      super
    end
  end
end
