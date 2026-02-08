# frozen_string_literal: true

require "yaml"
require "fileutils"

module FixtureBot
  class Compiler
    def initialize(fixture_set)
      @fixture_set = fixture_set
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
      records.each do |record_name, columns|
        hash[record_name.to_s] = columns.transform_keys(&:to_s)
      end
      YAML.dump(hash)
    end
  end
end
