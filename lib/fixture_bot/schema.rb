# frozen_string_literal: true

module FixtureBot
  class Schema
    Table = Data.define(:name, :columns, :belongs_to_associations)
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

      def table(name, columns: [], &block)
        associations = []
        if block
          table_builder = TableBuilder.new(associations)
          table_builder.instance_eval(&block)
        end
        @schema.tables[name] = Table.new(name: name, columns: columns, belongs_to_associations: associations)
      end

      def join_table(name, left_table, right_table)
        left_fk = :"#{singularize(left_table)}_id"
        right_fk = :"#{singularize(right_table)}_id"
        @schema.join_tables[name] = JoinTable.new(
          name: name,
          left_table: left_table,
          right_table: right_table,
          left_foreign_key: left_fk,
          right_foreign_key: right_fk
        )
      end

      private

      def singularize(name)
        word = name.to_s
        if word.end_with?("ies")
          word[0..-4] + "y"
        elsif word.end_with?("ses", "xes", "zes", "ches", "shes")
          word[0..-3]
        elsif word.end_with?("s") && !word.end_with?("ss")
          word[0..-2]
        else
          word
        end
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
