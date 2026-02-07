# frozen_string_literal: true

module FixtureBot
  class GeneratorContext
    def initialize(record_name:, literal_values: {})
      @record_name = record_name
      @literal_values = literal_values
    end

    def name
      @literal_values.key?(:name) ? @literal_values[:name] : @record_name
    end

    private

    def method_missing(method_name, *args, &block)
      if @literal_values.key?(method_name)
        @literal_values[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @literal_values.key?(method_name) || super
    end
  end
end
