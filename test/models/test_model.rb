# frozen_string_literal: true

require 'radical'

class TestModel < Radical::Model
  class << self
    def db
      true
    end

    def columns
      ['id']
    end
  end
end
