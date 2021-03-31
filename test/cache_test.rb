# frozen_string_literal: true

require 'test_helper'

class CacheTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Cache::VERSION
  end

  def test_it_writes_into_the_cache
    result = Cache.write('test/string', 'test')
    assert result == 'OK'
  end

  def test_it_reads_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.read('test/string')
    assert result == 'test'
  end

  def test_it_doesnt_reads_into_the_cache
    result = Cache.read('test/string/1234')
    assert result.nil?
  end

  def test_it_fetch_and_read_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.fetch('test/string')
    assert result == 'test'
  end

  def test_it_fetch_and_force_writes_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.fetch('test/string', expires_in: 60, force: true) do
      'test2'
    end
    assert result == 'test2'
  end

  def test_it_fetch_and_writes_into_the_cache
    result = Cache.fetch('test/string/2', expires_in: 60) do
      'test2'
    end
    assert result == 'test2'
  end

  def test_it_checks_key_for_existence
    Cache.write('test/string', 'test')
    result = Cache.exists?('test/string')
    assert result == true
  end

  def test_it_checks_key_for_non_existence
    result = Cache.exists?('test/string/1234')
    assert result == false
  end

  def test_it_deletes_into_the_cache
    Cache.write('test/string', 'test')
    result = Cache.delete('test_key')
    refute_nil result
  end

  def test_it_writes_json_into_the_cache
    message = { a: 'test', b: 'azerty' }
    result = Cache.write('test/json', message)
    assert result == 'OK'
  end

  def test_it_reads_json_into_the_cache
    test_it_writes_json_into_the_cache
    result = Cache.read('test/json')
    assert result[:a] == 'test'
    assert result[:b] == 'azerty'
  end
end
