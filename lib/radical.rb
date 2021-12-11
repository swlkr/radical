# frozen_string_literal: true

require_relative 'radical/app'
require_relative 'radical/controller'
require_relative 'radical/view'
require_relative 'radical/model'
require_relative 'radical/migration'
require_relative 'radical/routes'
require_relative 'radical/env'

module Radical
  def self.env
    Radical::Env
  end
end
