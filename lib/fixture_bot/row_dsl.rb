# frozen_string_literal: true

module FixtureBot
  class RowDSL
    attr_reader :literal_values, :association_refs, :tag_refs

    def self.for(table_def, schema)
      klass = Class.new(self)

      table_def.columns.each do |col|
        klass.define_method(col) do |value|
          @literal_values[col] = value
        end
      end

      table_def.belongs_to_associations.each do |assoc|
        klass.define_method(assoc.name) do |ref|
          @association_refs[assoc.name] = ref
        end
      end

      schema.join_tables.each_value do |jt|
        if jt.left_table == table_def.name
          klass.define_method(jt.right_table) do |*refs|
            @tag_refs[jt.name] = { table: jt.right_table, refs: refs }
          end
        elsif jt.right_table == table_def.name
          klass.define_method(jt.left_table) do |*refs|
            @tag_refs[jt.name] = { table: jt.left_table, refs: refs }
          end
        end
      end

      klass.new
    end

    def initialize
      @literal_values = {}
      @association_refs = {}
      @tag_refs = {}
    end
  end
end
