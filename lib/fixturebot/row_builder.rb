# frozen_string_literal: true

module FixtureBot
  class RowBuilder
    def initialize(row:, table:, defaults:, join_tables:)
      @row = row
      @table = table
      @defaults = defaults
      @join_tables = join_tables
    end

    def id
      @id ||= Key.generate(@row.table, @row.name)
    end

    def record
      result = { id: id }
      @table.columns.each do |col|
        if @row.literal_values.key?(col)
          result[col] = @row.literal_values[col]
        elsif foreign_key_values.key?(col)
          result[col] = foreign_key_values[col]
        elsif defaulted_values.key?(col)
          result[col] = defaulted_values[col]
        end
      end
      result
    end

    def join_rows
      @row.tag_refs.flat_map do |join_table_name, tag_info|
        jt = @join_tables[join_table_name]
        tag_info[:refs].map do |tag_ref|
          build_join_row(jt, tag_info[:table], tag_ref)
        end
      end
    end

    private

    def build_join_row(jt, other_table, tag_ref)
      other_id = Key.generate(other_table, tag_ref)

      if jt.left_table == @row.table
        {
          key: :"#{@row.name}_#{tag_ref}",
          join_table: jt.name,
          row: { jt.left_foreign_key => id, jt.right_foreign_key => other_id }
        }
      else
        {
          key: :"#{tag_ref}_#{@row.name}",
          join_table: jt.name,
          row: { jt.left_foreign_key => other_id, jt.right_foreign_key => id }
        }
      end
    end

    def foreign_key_values
      @foreign_key_values ||= @row.association_refs.each_with_object({}) do |(assoc_name, ref), hash|
        assoc = @table.belongs_to_associations.find { |a| a.name == assoc_name }
        hash[assoc.foreign_key] = Key.generate(assoc.table, ref)
      end
    end

    def defaulted_values
      @defaulted_values ||= @defaults.each_with_object({}) do |(col, block), result|
        next if @row.literal_values.key?(col)
        next if foreign_key_values.key?(col)

        context = DefaultContext.new(
          record_name: @row.name,
          literal_values: @row.literal_values
        )
        result[col] = context.instance_eval(&block)
      end
    end
  end
end
