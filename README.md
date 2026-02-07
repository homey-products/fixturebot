# FixtureBot

Rails fixtures are fast — they're loaded once into the database and wrapped in transactions, so your tests don't pay the cost of creating records on every run. But writing YAML by hand is verbose, error-prone, and painful to maintain at scale.

Factories like FactoryBot have a great DSL, but they're slow. Every test creates records from scratch, and that cost compounds as your suite grows.

FixtureBot gives you the best of both: a Ruby DSL that feels like FactoryBot, backed by the speed of Rails fixtures. You define your test data in Ruby, and FixtureBot generates standard YAML fixture files that Rails loads normally.

## Installation

Add to your Gemfile:

```ruby
gem "fixturebot"
```

### Rails generator

The easiest way to get started is with the install generator:

```bash
rails generate fixturebot:install
```

This will:

- Create `spec/fixtures.rb` (RSpec) or `test/fixtures.rb` (Minitest) with a skeleton DSL file
- Add the appropriate require to your test helper

### Manual setup

#### RSpec

Add to `spec/rails_helper.rb`:

```ruby
require "fixturebot/rspec"
```

Create `spec/fixtures.rb` with your fixture definitions (see [The DSL](#the-dsl) below).

Fixtures are auto-generated before each suite run — no rake task needed.

#### Minitest

Add to `test/test_helper.rb`:

```ruby
require "fixturebot/minitest"
```

Create `test/fixtures.rb` with your fixture definitions (see [The DSL](#the-dsl) below).

Fixtures are auto-generated when the helper is loaded — no rake task needed.

### Rake task

A `fixturebot:generate` rake task is also available if you prefer manual control:

```bash
bundle exec rake fixturebot:generate
```

### Configuration

FixtureBot auto-detects your fixtures file (`test/fixtures.rb` or `spec/fixtures.rb`) and derives the output directory by stripping `.rb` (e.g. `spec/fixtures.rb` writes to `spec/fixtures/`). To override:

```ruby
# config/application.rb or config/environments/test.rb
config.fixturebot.fixtures_file = "test/my_fixtures.rb"
config.fixturebot.output_dir = "test/fixtures"
```

## How it works

1. You define your fixtures in a Ruby DSL file
2. Before your test suite runs, FixtureBot reads your database schema and generates YAML fixture files
3. Rails loads those fixtures as usual

The generated YAML files are static snapshots you can inspect, diff, and commit. There's no magic at test time — Rails just sees normal fixtures.

## Quick example

```ruby
# spec/fixtures.rb
FixtureBot.define do
  # Generators fill in required columns so you don't have to repeat yourself.
  # This one gives every user an email unless the record overrides it.
  user.email { "#{name}@example.com" }

  user :brad do
    name "Brad"
    email "brad@example.com"  # overrides the generator
  end

  user :alice do
    name "Alice"              # email filled in by generator: "Alice@example.com"
  end

  user :deactivated do
    name "Ghost"
    email nil                 # explicit nil — generator skipped, email set to null
  end

  post :hello_world do
    title "Hello World"
    body "Welcome to the blog!"
    author :brad
    tags :ruby, :rails
  end

  tag :ruby do
    name "Ruby"
  end

  tag :rails do
    name "Rails"
  end
end
```

This generates YAML files like `users.yml`, `posts.yml`, `tags.yml`, and `posts_tags.yml` in your fixtures directory. Use them in tests like any other fixture:

```ruby
# RSpec
RSpec.describe Post, type: :model do
  fixtures :all

  it "belongs to an author" do
    post = posts(:hello_world)
    expect(post.author).to eq(users(:brad))
  end
end

# Minitest
class PostTest < ActiveSupport::TestCase
  def test_belongs_to_author
    post = posts(:hello_world)
    assert_equal users(:brad), post.author
  end
end
```

## The DSL

### Records

Define named records with literal column values:

```ruby
FixtureBot.define do
  user :brad do
    name "Brad"
    email "brad@example.com"
  end
end
```

Records without a block get an auto-generated ID and any generator defaults:

```ruby
FixtureBot.define do
  user.email { "#{name}@example.com" }

  user :alice
  # => { id: <stable_id>, email: "alice@example.com" }
end
```

### Generators

Generators set default column values. They run for each record that doesn't explicitly set that column. Generators are never created implicitly — columns without a value or generator are omitted from the YAML output (Rails uses the database column default).

```ruby
FixtureBot.define do
  user.email { "#{name}@example.com" }
end
```

The generator block has access to `name`, which returns the record's literal `name` column if set, or the record name (e.g. `:brad`) as a fallback.

A literal value shadows the generator. An explicit `nil` also shadows it:

```ruby
FixtureBot.define do
  user.email { "#{name}@example.com" }

  user :brad do
    name "Brad"
    email "brad@hey.com"  # literal — skips the generator
  end

  user :alice do
    name "Alice"
    # no email set — generator produces "Alice@example.com"
  end

  user :deactivated do
    name "Ghost"
    email nil              # explicit nil — skips the generator, sets email to null
  end
end
```

### Associations

Reference other records by name for `belongs_to`:

```ruby
FixtureBot.define do
  post :hello_world do
    title "Hello World"
    author :brad  # sets author_id to brad's stable ID
  end
end
```

### Join tables (HABTM)

Reference multiple records for join table associations:

```ruby
FixtureBot.define do
  post :hello_world do
    title "Hello World"
    tags :ruby, :rails  # creates rows in posts_tags
  end
end
```

### Implicit vs explicit style

By default, the block is evaluated implicitly — table methods like `user` and `post` are available directly:

```ruby
FixtureBot.define do
  user :brad do
    name "Brad"
  end
end
```

If you prefer an explicit receiver (useful for editor autocompletion or clarity in large files), pass a block argument:

```ruby
FixtureBot.define do |t|
  t.user :brad do
    name "Brad"
  end
end
```

Both styles are equivalent. Record blocks (the inner `do...end`) are always implicit.

### Schema

FixtureBot reads your database schema automatically in Rails. Outside of Rails, you can define it by hand:

```ruby
FixtureBot::Schema.define do
  table :users, singular: :user, columns: [:name, :email]

  table :posts, singular: :post, columns: [:title, :body, :author_id] do
    belongs_to :author, table: :users
  end

  table :tags, singular: :tag, columns: [:name]

  join_table :posts_tags, :posts, :tags
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

Try the playground without Rails:

```bash
bundle exec exe/fixturebot show ./playground/blog
```
