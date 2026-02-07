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
    end

    private

    def method_missing(method_name, *args, &block)
      if @table_def.columns.include?(method_name)
        @literal_values[method_name] = args.first
      elsif (assoc = @table_def.belongs_to_associations.find { |a| a.name == method_name })
        @association_refs[assoc.name] = args.first
      elsif (jt = find_join_table(method_name))
        @tag_refs[jt[:join_table].name] = { table: jt[:other_table], refs: args }
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @table_def.columns.include?(method_name) ||
        @table_def.belongs_to_associations.any? { |a| a.name == method_name } ||
        !!find_join_table(method_name) ||
        super
    end

    def find_join_table(method_name)
      @schema.join_tables.each_value do |jt|
        if jt.left_table == @table_def.name && jt.right_table == method_name
          return { join_table: jt, other_table: jt.right_table }
        elsif jt.right_table == @table_def.name && jt.left_table == method_name
          return { join_table: jt, other_table: jt.left_table }
        end
      end
      nil
    end
  end
end
