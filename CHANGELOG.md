# Changelog

## 0.2.0

### Breaking changes

- **Generator block parameter:** Generator blocks now receive a `fixture` object as a block parameter instead of the magic `name` method. Use `fixture.key` to get the record's symbol name. Column values are available as bare methods inside the block.

  ```ruby
  # Before
  user.email { "#{name}@example.com" }

  # After
  user.email { |fixture| "#{fixture.key}@example.com" }
  ```

### Improvements

- Rename `YamlDumper` to `Compiler`, `generate`/`dump` to `compile`
- Rename rake task from `fixturebot:generate` to `fixturebot:compile`
- Strip YAML document prefix (`---`) from compiled output
- Fix CLI entrypoint to detect Rails app instead of rescuing LoadError
- Internal refactor: group classes into `Row` and `Default` modules, replace `method_missing` with `define_singleton_method`

## 0.1.1

- Internal refactoring and README updates

## 0.1.0

- Initial release
- Ruby DSL for defining fixtures with generators, associations, and join tables
- Auto-generates YAML fixture files from database schema
- RSpec and Minitest integration with auto-generation hooks
- Rails Railtie with `config.fixturebot` namespace and `fixturebot:generate` rake task
- Install generator: `rails generate fixturebot:install`
