# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/strings'

class TestStrings < Minitest::Test
  def test_camel_case
    assert_equal 'Hello', Radical::Strings.camel_case('hello')
  end

  def test_snake_case
    assert_equal 'hello_world', Radical::Strings.snake_case('HelloWorld')
  end
end
