# frozen_string_literal: true

require_relative "stable_id"
require_relative "generator_context"

module FixtureBot
  class FixtureSet
    attr_reader :tables

    def initialize(schema, definition)
      @schema = schema
      @tables = {}
      finalize(definition)
    end

    private

    def finalize(definition)
      # Initialize output tables
      @schema.tables.each_key { |name| @tables[name] = {} }
      @schema.join_tables.each_key { |name| @tables[name] = {} }

      # Process each row
      definition.rows.each do |row|
        table_name = row[:table]
        record_name = row[:name]
        table_def = @schema.tables[table_name]
        generators = definition.generators[table_name]

        id = StableId.generate(table_name, record_name)
        literal_values = row[:literal_values]

        # Resolve belongs_to foreign keys
        fk_values = {}
        row[:association_refs].each do |assoc_name, ref|
          assoc = table_def.belongs_to_associations.find { |a| a.name == assoc_name }
          fk_values[assoc.foreign_key] = StableId.generate(assoc.table, ref)
        end

        # Run generators for columns not set literally and not FK columns
        generated_values = {}
        generators.each do |col, block|
          next if literal_values.key?(col)
          next if fk_values.key?(col)

          context = GeneratorContext.new(
            record_name: record_name,
            table: table_name,
            literal_values: literal_values
          )
          generated_values[col] = context.instance_eval(&block)
        end

        # Build final record
        record = { id: id }
        table_def.columns.each do |col|
          if literal_values.key?(col)
            record[col] = literal_values[col]
          elsif fk_values.key?(col)
            record[col] = fk_values[col]
          elsif generated_values.key?(col)
            record[col] = generated_values[col]
          end
        end

        @tables[table_name][record_name] = record

        # Handle HABTM join table rows
        row[:tag_refs].each do |join_table_name, tag_info|
          jt = @schema.join_tables[join_table_name]
          tag_info[:refs].each do |tag_ref|
            # Determine which side this record is on
            if jt.left_table == table_name
              left_id = id
              right_id = StableId.generate(tag_info[:table], tag_ref)
              join_key = :"#{record_name}_#{tag_ref}"
              join_row = {
                jt.left_foreign_key => left_id,
                jt.right_foreign_key => right_id
              }
            else
              left_id = StableId.generate(tag_info[:table], tag_ref)
              right_id = id
              join_key = :"#{tag_ref}_#{record_name}"
              join_row = {
                jt.left_foreign_key => left_id,
                jt.right_foreign_key => right_id
              }
            end
            @tables[join_table_name][join_key] = join_row
          end
        end
      end
    end
  end
end
