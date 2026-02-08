# frozen_string_literal: true

module FixtureBot
  module Default
    Fixture = Data.define(:key)

    class Definition
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

    class Context
      def initialize(literal_values: {})
        define_literal_value_methods(literal_values)
      end

      private

      def define_literal_value_methods(literal_values)
        literal_values.each do |col, val|
          define_singleton_method(col) { val }
        end
      end
    end
  end
end
