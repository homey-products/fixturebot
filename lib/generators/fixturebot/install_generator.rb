# frozen_string_literal: true

require "rails/generators"

module Fixturebot
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    desc "Set up FixtureBot in your Rails application"

    def create_fixtures_file
      if rspec?
        template "fixtures.rb.tt", "spec/fixtures.rb"
      else
        template "fixtures.rb.tt", "test/fixtures.rb"
      end
    end

    def inject_require_into_helper
      if rspec?
        inject_into_file "spec/rails_helper.rb",
          "require \"fixturebot/rspec\"\n",
          after: "require 'rspec/rails'\n"
      else
        inject_into_file "test/test_helper.rb",
          "require \"fixturebot/minitest\"\n",
          after: "require \"rails/test_help\"\n"
      end
    end

    private

    def rspec?
      File.directory?(File.join(destination_root, "spec"))
    end
  end
end
