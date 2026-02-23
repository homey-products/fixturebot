# frozen_string_literal: true

require "yaml"
require "fileutils"

module FixtureBot
  class Compiler
    def initialize(fixture_set, schema: nil)
      @fixture_set = fixture_set
      @schema = schema
    end

    def compile(output_dir)
      FileUtils.mkdir_p(output_dir)
      @fixture_set.tables.each do |table_name, records|
        next if records.empty?
        path = File.join(output_dir, "#{table_name}.yml")
        File.write(path, compile_table(table_name))
      end
    end

    def compile_table(table_name)
      records = @fixture_set.tables[table_name]
      hash = {}

      # Add _fixture model_class directive if the model name differs from what
      # Rails would infer from the table name (e.g., agency_branches → Branch, not AgencyBranch)
      model_class = @schema&.class_name_map&.dig(table_name)
      if model_class
        expected = ActiveSupport::Inflector.classify(table_name.to_s)
        if model_class != expected
          hash["_fixture"] = { "model_class" => model_class }
        end
      end

      records.each do |record_name, columns|
        hash[record_name.to_s] = columns.transform_keys(&:to_s)
      end
      YAML.dump(hash).delete_prefix("---\n")
    end
  end
end
