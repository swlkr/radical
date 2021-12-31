# frozen_string_literal: true

module Radical
  class Tag
    SELF_CLOSING_TAGS = %w[area base br col embed hr img input keygen link meta param source track wbr].freeze

    def initialize
      self
    end

    def method_missing(name, *args, &block)
      self.class.string(name, *args, &block)
    end

    def respond_to_missing?
      true
    end

    def self.open_tag(name, attrs)
      attr_string = attrs.empty? ? '' : " #{attribute_string(attrs)}"
      open_tag_str = "<#{name}"
      self_closing = SELF_CLOSING_TAGS.include?(name)

      "#{open_tag_str}#{attr_string}#{self_closing ? '' : '>'}"
    end

    def self.close_tag(name)
      self_closing = SELF_CLOSING_TAGS.include?(name)

      if self_closing
        ' />'
      else
        "</#{name}>"
      end
    end

    def self.attribute_string(attributes = {})
      attributes.transform_keys(&:to_s).sort_by { |k, _| k }.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    end

    def self.string(name, attrs = {}, &block)
      "#{open_tag(name, attrs)}#{yield if block}#{close_tag(name)}"
    end
  end
end
