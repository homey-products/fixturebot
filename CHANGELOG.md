# Changelog

## 0.1.0

- Initial release
- Ruby DSL for defining fixtures with generators, associations, and join tables
- Auto-generates YAML fixture files from database schema
- RSpec and Minitest integration with auto-generation hooks
- Rails Railtie with `config.fixturebot` namespace and `fixturebot:generate` rake task
- Install generator: `rails generate fixturebot:install`
