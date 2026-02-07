# frozen_string_literal: true

module FixtureBot
  class GeneratorProxy
    def self.for(table_def, generators)
      klass = Class.new(self)

      table_def.columns.each do |col|
        klass.define_method(col) do |&block|
          raise ArgumentError, "#{col} requires a block" unless block
          @generators[col] = block
        end
      end

      klass.new(generators)
    end

    def initialize(generators)
      @generators = generators
    end
  end
end
