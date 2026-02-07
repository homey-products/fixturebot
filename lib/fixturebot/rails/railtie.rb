# frozen_string_literal: true

module FixtureBot
  module Rails
    class Railtie < ::Rails::Railtie
      config.fixturebot = ActiveSupport::OrderedOptions.new

      rake_tasks do
        namespace :fixturebot do
          desc "Generate YAML fixture files from FixtureBot DSL"
          task generate: :environment do
            FixtureBot::Rails.generate
          end
        end
      end
    end
  end
end
