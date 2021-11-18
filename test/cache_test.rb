# frozen_string_literal: true

require 'test_helper'

class CacheTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Cache::VERSION
  end

  def test_it_writes_into_the_cache
    result = Cache.write('test/string', 'test')
    assert_equal('OK', result)
  end

  def test_it_reads_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.read('test/string')
    assert_equal('test', result)
  end

  def test_it_doesnt_reads_into_the_cache
    result = Cache.read('test/string/1234')
    assert_nil(result)
  end

  def test_it_fetch_and_read_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.fetch('test/string')
    assert_equal('test', result)
  end

  def test_it_fetch_and_force_writes_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.fetch('test/string', expires_in: 60, force: true) do
      'test2'
    end
    assert_equal('test2', result)
  end

  def test_it_fetch_and_writes_into_the_cache
    result = Cache.fetch('test/string/2', expires_in: 60) do
      'test2'
    end
    assert_equal('test2', result)
  end

  def test_it_checks_key_for_existence
    Cache.write('test/string', 'test')
    result = Cache.exists?('test/string')
    assert(result)
  end

  def test_it_checks_key_for_non_existence
    result = Cache.exists?('test/string/1234')
    refute(result)
  end

  def test_it_deletes_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.delete('test_key')
    refute_nil result
  end

  def test_it_writes_json_into_the_cache
    message = { a: 'test', b: 'azerty' }
    result = Cache.write('test/json', message)
    assert_equal('OK', result)
  end

  def test_it_reads_json_into_the_cache
    test_it_writes_json_into_the_cache
    result = Cache.read('test/json')
    assert_equal('test', result[:a])
    assert_equal('azerty', result[:b])
  end

  def test_it_increments_a_counter
    Cache.delete('test/inc')
    result = Cache.increment('test/inc', 1)
    assert_equal(1, result)
  end

  def test_it_increments_a_counter_twice
    Cache.delete('test/inc')
    Cache.increment('test/inc', 1)
    result = Cache.increment('test/inc', 1)
    assert_equal(2, result)
  end

  def test_it_decrements_a_counter
    Cache.delete('test/inc')
    Cache.increment('test/inc', 1)
    Cache.increment('test/inc', 1)
    result = Cache.decrement('test/inc')
    assert_equal(1, result)
  end
end
