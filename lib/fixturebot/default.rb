# frozen_string_literal: true

module FixtureBot
  class Default
    def initialize(table, defaults)
      @defaults = defaults
      define_column_methods(table)
    end

    private

    def define_column_methods(table)
      table.columns.each do |col|
        define_singleton_method(col) do |&block|
          raise ArgumentError, "#{col} requires a block" unless block
          @defaults[col] = block
        end
      end
    end
  end
end
