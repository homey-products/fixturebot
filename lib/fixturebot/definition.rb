# frozen_string_literal: true

module FixtureBot
  class Definition
    attr_reader :generators, :rows

    def initialize(schema)
      @schema = schema
      @generators = {}
      @rows = []
      @singular_to_table = {}

      schema.tables.each_value do |table_def|
        @generators[table_def.name] = {}
        @singular_to_table[table_def.singular_name] = table_def
      end
    end

    private

    def method_missing(method_name, *args, &block)
      table_def = @singular_to_table[method_name]
      return super unless table_def

      record_name = args.first

      if record_name.nil? && block.nil?
        GeneratorProxy.new(table_def, @generators[table_def.name])
      elsif record_name
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
        raise ArgumentError, "#{table_def.singular_name} requires a record name or no arguments"
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @singular_to_table.key?(method_name) || super
    end
  end
end
