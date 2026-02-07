# frozen_string_literal: true

module FixtureBot
  class Definition
    attr_reader :generators, :rows

    def initialize(schema)
      @schema = schema
      @generators = {}
      @rows = []

      schema.tables.each_value do |table_def|
        @generators[table_def.name] = {}
      end
    end

    private

    def method_missing(method_name, *args, &block)
      table_def = find_table(method_name)
      return super unless table_def

      if args.empty? && block.nil?
        GeneratorProxy.new(table_def, @generators[table_def.name])
      elsif args.first
        record_name = args.first
        row_dsl = RowDSL.new(table_def, @schema)
        row_dsl.instance_eval(&block) if block
        @rows << Row.new(
          table: table_def.name,
          name: record_name,
          literal_values: row_dsl.literal_values,
          association_refs: row_dsl.association_refs,
          tag_refs: row_dsl.tag_refs
        )
      else
        raise ArgumentError, "#{method_name} requires a record name or no arguments"
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      find_table(method_name) || super
    end

    def find_table(singular_name)
      @schema.tables.values.find { |t| t.singular_name.to_s == singular_name.to_s }
    end
  end
end
