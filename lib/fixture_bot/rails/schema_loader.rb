# frozen_string_literal: true

require "active_record"

module FixtureBot
  module Rails
    class SchemaLoader

      def self.load_file(path)
        new.load_file(path)
      end

      def load_file(path)
        ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
        load(path)

        conn = ActiveRecord::Base.connection
        build_schema(conn)
      ensure
        ActiveRecord::Base.connection_pool.disconnect!
      end

      private

      INTERNAL_TABLES = %w[ar_internal_metadata schema_migrations].freeze

      def build_schema(conn)
        schema = Schema.new
        table_names = conn.tables - INTERNAL_TABLES

        join_table_names = detect_join_tables(conn, table_names)

        (table_names - join_table_names).each do |name|
          columns = conn.columns(name)
            .reject { |c| skip_column?(c.name) }
            .map { |c| c.name.to_sym }

          foreign_keys = conn.foreign_keys(name)
          associations = foreign_keys.map do |fk|
            assoc_name = fk.column.sub(/_id$/, "")
            Schema::BelongsTo.new(
              name: assoc_name.to_sym,
              table: fk.to_table.to_sym,
              foreign_key: fk.column.to_sym
            )
          end

          schema.tables[name.to_sym] = Schema::Table.new(
            name: name.to_sym,
            singular_name: ActiveSupport::Inflector.singularize(name).to_sym,
            columns: columns,
            belongs_to_associations: associations
          )
        end

        join_table_names.each do |name|
          fk_columns = conn.columns(name)
            .select { |c| c.name.end_with?("_id") }
            .map { |c| c.name }

          schema.join_tables[name.to_sym] = Schema::JoinTable.new(
            name: name.to_sym,
            left_table: ActiveSupport::Inflector.pluralize(fk_columns[0].sub(/_id$/, "")).to_sym,
            right_table: ActiveSupport::Inflector.pluralize(fk_columns[1].sub(/_id$/, "")).to_sym,
            left_foreign_key: fk_columns[0].to_sym,
            right_foreign_key: fk_columns[1].to_sym
          )
        end

        schema
      end

      def skip_column?(name)
        %w[id created_at updated_at].include?(name)
      end

      def detect_join_tables(conn, table_names)
        table_names.select do |name|
          pk = conn.primary_key(name)
          next false if pk

          id_cols = conn.columns(name).select { |c| c.name.end_with?("_id") }
          id_cols.size == 2
        end
      end
    end
  end
end
