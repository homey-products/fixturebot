# frozen_string_literal: true

require_relative "generator_proxy"
require_relative "row_dsl"

module FixtureBot
  class Definition
    attr_reader :generators, :rows

    def initialize(schema)
      @schema = schema
      @generators = {} # { table_name => { column => block } }
      @rows = []       # [{ table:, name:, literal_values:, association_refs:, tag_refs: }]

      schema.tables.each_value do |table_def|
        singular = table_def.singular_name.to_s
        @generators[table_def.name] = {}

        define_singleton_method(singular) do |record_name = nil, &block|
          if record_name.nil? && block.nil?
            # Generator mode: user.email { ... }
            GeneratorProxy.new(table_def, @generators[table_def.name])
          elsif record_name
            # Row mode: user :admin do ... end
            row_dsl = RowDSL.new(table_def, @schema)
            row_dsl.instance_eval(&block) if block
            @rows << {
              table: table_def.name,
              name: record_name,
              literal_values: row_dsl.literal_values,
              association_refs: row_dsl.association_refs,
              tag_refs: row_dsl.tag_refs
            }
          else
            raise ArgumentError, "#{singular} requires a record name or no arguments"
          end
        end
      end
    end

  end
end
