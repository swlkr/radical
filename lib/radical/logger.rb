# frozen_string_literal: true

require 'logger'

module Radical
  class Logger < ::Logger
    def initialize(*)
      super
      @formatter = LogFmtFormatter.new
    end
  end

  class LogFmtFormatter < ::Logger::Formatter
    def call(severity, datetime, progname, msg)
      formatted_datetime = datetime.strftime('%Y-%m-%d %H:%M:%S.%L')

      "[#{formatted_datetime}] level=#{severity.downcase} in=#{progname} msg=#{msg}\n"
    end
  end
end
