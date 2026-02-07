# frozen_string_literal: true

module FixtureBot
  class GeneratorProxy
    def initialize(table_def, generators)
      @table_def = table_def
      @generators = generators
    end

    private

    def method_missing(method_name, *args, &block)
      if @table_def.columns.include?(method_name)
        raise ArgumentError, "#{method_name} requires a block" unless block
        @generators[method_name] = block
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @table_def.columns.include?(method_name) || super
    end
  end
end
