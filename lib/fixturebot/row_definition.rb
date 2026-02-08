# frozen_string_literal: true

module FixtureBot
  class RowDefinition
    attr_reader :literal_values, :association_refs, :tag_refs

    def initialize(table, schema)
      @literal_values = {}
      @association_refs = {}
      @tag_refs = {}

      define_column_methods(table)
      define_association_methods(table)
      define_join_table_methods(table, schema)
    end

    private

    def define_column_methods(table)
      table.columns.each do |col|
        define_singleton_method(col) do |value|
          @literal_values[col] = value
        end
      end
    end

    def define_association_methods(table)
      table.belongs_to_associations.each do |assoc|
        define_singleton_method(assoc.name) do |ref|
          @association_refs[assoc.name] = ref
        end
      end
    end

    def define_join_table_methods(table, schema)
      schema.join_tables.each_value do |jt|
        if jt.left_table == table.name
          define_singleton_method(jt.right_table) do |*refs|
            @tag_refs[jt.name] = { table: jt.right_table, refs: refs }
          end
        elsif jt.right_table == table.name
          define_singleton_method(jt.left_table) do |*refs|
            @tag_refs[jt.name] = { table: jt.left_table, refs: refs }
          end
        end
      end
    end
  end
end
