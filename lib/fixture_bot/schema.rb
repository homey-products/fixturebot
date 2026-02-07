# frozen_string_literal: true

module FixtureBot
  class Schema
    Table = Data.define(:name, :singular_name, :columns, :belongs_to_associations)
    BelongsTo = Data.define(:name, :table, :foreign_key)
    JoinTable = Data.define(:name, :left_table, :right_table, :left_foreign_key, :right_foreign_key)

    attr_reader :tables, :join_tables

    def initialize
      @tables = {}
      @join_tables = {}
    end

    def self.define(&block)
      schema = new
      builder = Builder.new(schema)
      builder.instance_eval(&block)
      schema
    end

    class Builder
      def initialize(schema)
        @schema = schema
      end

      def table(name, singular:, columns: [], &block)
        associations = []
        if block
          table_builder = TableBuilder.new(associations)
          table_builder.instance_eval(&block)
        end
        @schema.tables[name] = Table.new(name: name, singular_name: singular, columns: columns, belongs_to_associations: associations)
      end

      def join_table(name, left_table, right_table)
        left_singular = @schema.tables[left_table].singular_name
        right_singular = @schema.tables[right_table].singular_name
        left_fk = :"#{left_singular}_id"
        right_fk = :"#{right_singular}_id"
        @schema.join_tables[name] = JoinTable.new(
          name: name,
          left_table: left_table,
          right_table: right_table,
          left_foreign_key: left_fk,
          right_foreign_key: right_fk
        )
      end
    end

    class TableBuilder
      def initialize(associations)
        @associations = associations
      end

      def belongs_to(name, table:)
        foreign_key = :"#{name}_id"
        @associations << BelongsTo.new(name: name, table: table, foreign_key: foreign_key)
      end
    end
  end
end
