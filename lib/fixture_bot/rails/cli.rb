# frozen_string_literal: true

require "optparse"

module FixtureBot
  module Rails
    class CLI
      def self.run(argv)
        new.run(argv)
      end

      def run(argv)
        args = argv.dup
        command = args.shift

        case command
        when "generate"
          run_generate(args)
        when "-v", "--version"
          puts "fixturebot #{FixtureBot::VERSION}"
        when "-h", "--help", nil
          puts help_text
        else
          $stderr.puts "Unknown command: #{command}"
          $stderr.puts help_text
          exit 1
        end
      end

      private

      def run_generate(args)
        schema_path = "db/schema.rb"

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: fixturebot generate [options] <fixtures.rb> [output_dir]"

          opts.on("-s", "--schema PATH", "Path to schema.rb (default: db/schema.rb)") do |path|
            schema_path = path
          end

          opts.on("-h", "--help", "Show help") do
            puts opts
            exit
          end
        end

        parser.parse!(args)

        fixtures_path = args.shift
        output_dir = args.shift || "test/fixtures"

        unless fixtures_path
          $stderr.puts "Error: fixtures file is required"
          $stderr.puts parser.to_s
          exit 1
        end

        unless File.exist?(schema_path)
          $stderr.puts "Error: schema file not found: #{schema_path}"
          exit 1
        end

        unless File.exist?(fixtures_path)
          $stderr.puts "Error: fixtures file not found: #{fixtures_path}"
          exit 1
        end

        schema = SchemaLoader.load_file(schema_path)
        fixture_set = FixtureBot.define_from_file(schema, fixtures_path)
        YamlDumper.new(fixture_set).dump(output_dir)

        puts "Generated fixtures in #{output_dir}/"
        fixture_set.tables.each do |table_name, records|
          next if records.empty?
          puts "  #{table_name}.yml (#{records.size} records)"
        end
      end

      def help_text
        <<~HELP
          Usage: fixturebot <command> [options]

          Commands:
            generate    Generate YAML fixtures from a DSL file

          Options:
            -v, --version    Show version
            -h, --help       Show help

          Example:
            fixturebot generate -s db/schema.rb fixtures.rb test/fixtures
        HELP
      end
    end
  end
end
