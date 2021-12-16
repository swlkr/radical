# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'
require 'models/test_model'

module Radical
  class TestFormsController < Controller
    def create; end
  end

  class TestFormModel < TestModel
    table 'test_forms'
  end

  class TestForm < Minitest::Test
    def setup
      @controller = TestFormsController.new(Rack::Request.new({}))
      @form = Form.new({}, @controller)
    end

    def test_submit_with_string
      assert_equal '<input type="submit" value="value" />', @form.submit('value')
    end

    def test_submit_with_hash
      assert_equal '<input type="submit" value="value" />', @form.submit(value: 'value')
    end

    def test_tag_with_no_attrs
      assert_equal '<div></div>', @form.send(:tag, 'div', {})
    end

    def test_button
      assert_equal '<button></button>', @form.button
    end

    def test_button_with_block
      assert_equal('<button>push me</button>', @form.button { 'push me' })
    end
  end
end
