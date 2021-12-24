# frozen_string_literal: true

require 'minitest/autorun'
require 'radical/model'

module Radical
  class V < Model
    table false

    validates do
      present :title
    end
  end

  class TestModel < Minitest::Test
    def setup
      @v = V.new(title: nil, name: 'name')
    end

    def test_validations
      @v.validate
      assert @v.invalid?
      assert_equal ['is not present'], @v.errors[:title]
      assert_equal 'name', @v.name
    end
  end
end
