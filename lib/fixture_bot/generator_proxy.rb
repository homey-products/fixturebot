# frozen_string_literal: true

module FixtureBot
  class GeneratorProxy
    attr_reader :generators

    def initialize(table_def, generators)
      @generators = generators

      table_def.columns.each do |col|
        define_singleton_method(col) do |&block|
          if block
            @generators[col] = block
          else
            raise ArgumentError, "#{col} requires a block when called on a generator proxy"
          end
        end
      end
    end
  end
end
