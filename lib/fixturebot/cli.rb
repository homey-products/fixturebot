# frozen_string_literal: true

require "thor"

module FixtureBot
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "show DIR", "Evaluate DIR/schema.rb and DIR/fixtures.rb, then print fixture YAML to stdout"
    def show(dir)
      schema_path = File.join(dir, "schema.rb")
      fixtures_path = File.join(dir, "fixtures.rb")

      raise Thor::Error, "Schema file not found: #{schema_path}" unless File.exist?(schema_path)
      raise Thor::Error, "Fixtures file not found: #{fixtures_path}" unless File.exist?(fixtures_path)

      schema = eval(File.read(schema_path), binding, schema_path, 1)
      fixture_set = FixtureBot.define_from_file(schema, fixtures_path)
      dumper = FixtureBot::YamlDumper.new(fixture_set)

      fixture_set.tables.each do |table_name, records|
        next if records.empty?
        puts "# #{table_name}.yml"
        puts dumper.dump_table(table_name)
      end
    end

    map %w[-v --version] => :version
    desc "version", "Show version"
    def version
      say "fixturebot #{FixtureBot::VERSION}"
    end
  end
end
