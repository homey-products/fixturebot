# frozen_string_literal: true

module FixtureBot
  class GeneratorContext
    attr_reader :record_name, :table

    def initialize(record_name:, table:, literal_values: {})
      @record_name = record_name
      @table = table

      # `name` defaults to record_name but can be shadowed by a literal column value
      define_singleton_method(:name) { record_name }

      # Shadow `name` and any other columns with literal values
      literal_values.each do |col, val|
        define_singleton_method(col) { val }
      end
    end
  end
end
