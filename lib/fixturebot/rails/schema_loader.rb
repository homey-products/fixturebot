# frozen_string_literal: true

require "active_record"

module FixtureBot
  module Rails
    class SchemaLoader

      def self.load(connection = ActiveRecord::Base.connection)
        new(connection).load
      end

      def initialize(connection)
        @connection = connection
      end

      def load
        build_schema
      end

      private

      def build_schema
        schema = Schema.new
        table_names = user_table_names

        join_table_names = detect_join_tables(table_names)

        (table_names - join_table_names).each do |name|
          schema.add_table(build_table(name))
        end

        join_table_names.each do |name|
          schema.add_join_table(build_join_table(name))
        end

        schema.class_name_map = build_class_name_map

        schema
      end

      def build_table(name)
        all_columns = @connection.columns(name)
        pk_column = all_columns.find { |c| c.name == "id" }
        uuid_pk = pk_column&.sql_type == "uuid"

        columns = all_columns
          .reject { |c| framework_column?(c.name) }
          .map { |c| c.name.to_sym }

        fk_associations = @connection.foreign_keys(name).map do |fk|
          Schema::BelongsTo.new(
            name: association_name(fk.column),
            table: fk.to_table.to_sym,
            foreign_key: fk.column.to_sym
          )
        end

        poly_associations = detect_polymorphic_associations(name, columns, fk_associations)

        Schema::Table.new(
          name: name.to_sym,
          singular_name: singularize(name),
          columns: columns,
          belongs_to_associations: fk_associations + poly_associations,
          uuid_pk: uuid_pk
        )
      end

      def detect_polymorphic_associations(table_name, columns, existing_associations)
        existing_fk_columns = existing_associations.map(&:foreign_key).to_set

        type_columns = columns.select { |c| c.to_s.end_with?("_type") }
        type_columns.filter_map do |type_col|
          id_col = :"#{type_col.to_s.sub(/_type$/, '_id')}"
          next unless columns.include?(id_col)
          next if existing_fk_columns.include?(id_col)

          assoc_name = type_col.to_s.sub(/_type$/, "").to_sym
          Schema::BelongsTo.new(
            name: assoc_name,
            table: nil, # resolved at row-build time from the tuple
            foreign_key: id_col,
            polymorphic: true,
            type_column: type_col
          )
        end
      end

      def build_class_name_map
        return {} unless defined?(ApplicationRecord)

        # Eager-load models so descendants are populated.
        if defined?(::Rails) && ::Rails.application
          begin
            ::Rails.application.eager_load!
          rescue => e
            ::Rails.logger&.warn("FixtureBot: eager_load! failed (#{e.class}: #{e.message}), using already-loaded models")
          end
        end

        map = {}
        ApplicationRecord.descendants.each do |klass|
          next if klass.abstract_class?

          table = klass.table_name&.to_sym
          next unless table

          # For STI: prefer the base class (not subclass) so the _fixture
          # model_class directive points to the right class.
          existing = map[table]
          if existing.nil?
            map[table] = klass.name
          else
            existing_klass = existing.constantize rescue nil
            if existing_klass && existing_klass < klass
              # existing is a subclass of klass — replace with klass (the base)
              map[table] = klass.name
            end
            # If klass < existing, keep existing (it's already the base)
            # If neither is a subclass of the other, keep the first one found
          end
        end
        map
      end

      def build_join_table(name)
        fk_columns = foreign_key_columns(name)

        Schema::JoinTable.new(
          name: name.to_sym,
          left_table: table_name_for_foreign_key(fk_columns[0]),
          right_table: table_name_for_foreign_key(fk_columns[1]),
          left_foreign_key: fk_columns[0].to_sym,
          right_foreign_key: fk_columns[1].to_sym
        )
      end

      def user_table_names
        @connection.tables - %w[ar_internal_metadata schema_migrations]
      end

      def framework_column?(name)
        %w[id created_at updated_at].include?(name)
      end

      def foreign_key_column?(column)
        column.name.end_with?("_id")
      end

      def foreign_key_columns(table_name)
        @connection.columns(table_name)
          .select { |c| foreign_key_column?(c) }
          .map { |c| c.name }
      end

      def association_name(column_name)
        column_name.sub(/_id$/, "").to_sym
      end

      def table_name_for_foreign_key(column_name)
        pluralize(column_name.sub(/_id$/, ""))
      end

      def singularize(word)
        ActiveSupport::Inflector.singularize(word).to_sym
      end

      def pluralize(word)
        ActiveSupport::Inflector.pluralize(word).to_sym
      end

      def detect_join_tables(table_names)
        table_names.select do |name|
          next false if @connection.primary_key(name)
          foreign_key_columns(name).size == 2
        end
      end
    end
  end
end
