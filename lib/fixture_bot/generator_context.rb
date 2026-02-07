# frozen_string_literal: true

module FixtureBot
  class GeneratorContext
    def initialize(record_name:, table:, literal_values: {})
      @record_name = record_name
      @table = table
      @literal_values = literal_values
    end

    private

    def method_missing(method_name, *args)
      if @literal_values.key?(method_name)
        @literal_values[method_name]
      elsif method_name == :name
        @record_name
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @literal_values.key?(method_name) || method_name == :name || super
    end
  end
end
