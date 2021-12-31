# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'

module Radical
  class TestTag < Minitest::Test
    def setup
      @tag = Tag.new
    end

    def test_tag_with_no_attrs
      assert_equal '<div></div>', Tag.string('div')
    end

    def test_button
      assert_equal '<button></button>', Tag.string('button')
    end

    def test_button_with_block
      actual = Tag.string('button', {}) { 'push me' }
      assert_equal('<button>push me</button>', actual)
    end

    def test_method_missing
      assert_equal '<div class="method-missing"></div>', @tag.div({ 'class' => 'method-missing' })
    end

    def input_self_closing
      assert_equal '<input type="text" />', @tag.input(type: 'text')
    end
  end
end
