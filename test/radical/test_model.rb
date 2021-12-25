# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/model'

module Radical
  class V < Model
    table false

    validates do
      present :title
      matches %r{/[A-Z]/}, :name
    end
  end

  class TestModel < Minitest::Test
    def test_validation
      v = V.new(title: nil, name: 'name')
      v.validate

      assert v.invalid?
      assert_equal 'name', v.name
      assert_equal ['is not present'], v.errors[:title]
      assert_equal ['does not match'], v.errors[:name]
    end
  end
end
