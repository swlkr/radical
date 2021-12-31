# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'
require 'models/model_test'

module Radical
  class TestFormsController < Controller
    def create; end
  end

  class TestFormModel < ModelTest
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
  end
end
