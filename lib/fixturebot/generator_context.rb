# frozen_string_literal: true

module FixtureBot
  class GeneratorContext
    def self.for(record_name:, table:, literal_values: {})
      klass = Class.new(self)

      klass.define_method(:name) { record_name }

      literal_values.each do |col, val|
        klass.define_method(col) { val }
      end

      klass.new
    end
  end
end
