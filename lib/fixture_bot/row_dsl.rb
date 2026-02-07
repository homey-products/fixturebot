# frozen_string_literal: true

module FixtureBot
  class RowDSL
    attr_reader :literal_values, :association_refs, :tag_refs

    def initialize(table_def, schema)
      @table_def = table_def
      @schema = schema
      @literal_values = {}
      @association_refs = {}
      @tag_refs = {}
      @join_table_map = build_join_table_map
    end

    private

    def method_missing(method_name, *args)
      if @table_def.columns.include?(method_name)
        @literal_values[method_name] = args.first
      elsif (assoc = find_association(method_name))
        @association_refs[assoc.name] = args.first
      elsif (jt_info = @join_table_map[method_name])
        @tag_refs[jt_info[:join_table]] = { table: jt_info[:other_table], refs: args }
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @table_def.columns.include?(method_name) ||
        find_association(method_name) ||
        @join_table_map.key?(method_name) ||
        super
    end

    def find_association(name)
      @table_def.belongs_to_associations.find { |a| a.name == name }
    end

    def build_join_table_map
      map = {}
      @schema.join_tables.each_value do |jt|
        if jt.left_table == @table_def.name
          map[jt.right_table] = { join_table: jt.name, other_table: jt.right_table }
        elsif jt.right_table == @table_def.name
          map[jt.left_table] = { join_table: jt.name, other_table: jt.left_table }
        end
      end
      map
    end
  end
end
