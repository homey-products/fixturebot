# frozen_string_literal: true

module FixtureBot
  class RowDSL
    attr_reader :literal_values, :association_refs, :tag_refs

    def initialize(table_def, schema)
      @literal_values = {}
      @association_refs = {}
      @tag_refs = {}

      # Define column setter methods
      table_def.columns.each do |col|
        define_singleton_method(col) do |value = :__unset__|
          if value == :__unset__
            raise ArgumentError, "#{col} requires a value"
          end
          @literal_values[col] = value
        end
      end

      # Define belongs_to association methods
      table_def.belongs_to_associations.each do |assoc|
        define_singleton_method(assoc.name) do |ref|
          @association_refs[assoc.name] = ref
        end
      end

      # Define tag/HABTM methods based on join tables
      schema.join_tables.each_value do |jt|
        if jt.left_table == table_def.name
          method_name = jt.right_table
          define_singleton_method(method_name) do |*refs|
            @tag_refs[jt.name] = { table: jt.right_table, refs: refs }
          end
        elsif jt.right_table == table_def.name
          method_name = jt.left_table
          define_singleton_method(method_name) do |*refs|
            @tag_refs[jt.name] = { table: jt.left_table, refs: refs }
          end
        end
      end
    end
  end
end
