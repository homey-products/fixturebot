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

    class Context
      def initialize(record_name:, literal_values: {})
        define_name_method(record_name, literal_values)
        define_literal_value_methods(literal_values)
      end

      private

      def define_name_method(record_name, literal_values)
        define_singleton_method(:name) do
          literal_values.key?(:name) ? literal_values[:name] : record_name
        end
      end

      def define_literal_value_methods(literal_values)
        literal_values.each do |col, val|
          next if col == :name
          define_singleton_method(col) { val }
        end
      end
    end
  end
end
