# frozen_string_literal: true

module FixtureBot
  class Schema
    Table = Data.define(:name, :singular_name, :columns, :belongs_to_associations, :uuid_pk) do
      def initialize(name:, singular_name:, columns:, belongs_to_associations:, uuid_pk: false)
        super
      end
    end
    BelongsTo = Data.define(:name, :table, :foreign_key, :polymorphic, :type_column) do
      def initialize(name:, table:, foreign_key:, polymorphic: false, type_column: nil)
        super
      end
    end
    JoinTable = Data.define(:name, :left_table, :right_table, :left_foreign_key, :right_foreign_key)

    attr_reader :tables, :join_tables, :class_name_map, :uuid_pk_tables

    def initialize
      @tables = {}
      @join_tables = {}
      @class_name_map = {}
      @uuid_pk_tables = Set.new
    end

    def add_table(table)
      @tables[table.name] = table
      @uuid_pk_tables.add(table.name) if table.uuid_pk
    end

    def class_name_map=(map)
      @class_name_map = map
    end

    def add_join_table(join_table)
      @join_tables[join_table.name] = join_table
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
        @schema.add_table(Table.new(
          name: name,
          singular_name: singular,
          columns: columns,
          belongs_to_associations: associations
        ))
      end

      def join_table(name, left_table, right_table)
        left_singular = @schema.tables[left_table].singular_name
        right_singular = @schema.tables[right_table].singular_name
        @schema.add_join_table(JoinTable.new(
          name: name,
          left_table: left_table,
          right_table: right_table,
          left_foreign_key: :"#{left_singular}_id",
          right_foreign_key: :"#{right_singular}_id"
        ))
      end
    end

    class TableBuilder
      def initialize(associations)
        @associations = associations
      end

      def belongs_to(name, table:, polymorphic: false)
        foreign_key = :"#{name}_id"
        type_column = polymorphic ? :"#{name}_type" : nil
        @associations << BelongsTo.new(
          name: name,
          table: table,
          foreign_key: foreign_key,
          polymorphic: polymorphic,
          type_column: type_column
        )
      end
    end
  end
end
