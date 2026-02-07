# frozen_string_literal: true

module FixtureBot
  class Definition
    attr_reader :generators, :rows

    def self.for(schema)
      klass = Class.new(self)

      schema.tables.each_value do |table_def|
        klass.define_method(table_def.singular_name) do |record_name = nil, &block|
          if record_name.nil? && block.nil?
            GeneratorProxy.for(table_def, @generators[table_def.name])
          elsif record_name
            row_dsl = RowDSL.for(table_def, @schema)
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
      end

      klass.new(schema)
    end

    def initialize(schema)
      @schema = schema
      @generators = {}
      @rows = []

      schema.tables.each_value do |table_def|
        @generators[table_def.name] = {}
      end
    end
  end
end
