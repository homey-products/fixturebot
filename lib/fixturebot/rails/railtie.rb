# frozen_string_literal: true

module FixtureBot
  module Rails
    class Railtie < ::Rails::Railtie
      config.fixturebot = ActiveSupport::OrderedOptions.new

      rake_tasks do
        namespace :fixturebot do
          desc "Compile FixtureBot DSL to YAML fixture files"
          task compile: :environment do
            FixtureBot::Rails.compile
          end
        end
      end
    end
  end
end
