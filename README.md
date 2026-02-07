# FixtureBot

FixtureBot lets you define Rails fixtures with a Ruby DSL instead of writing YAML by hand. It generates standard fixture YAML files that Rails loads normally, so you get a readable DSL on top of the battle-tested fixtures system you already know.

## Installation

Add to your Gemfile:

```ruby
group :development, :test do
  gem "fixturebot-rails"
end
```

## How it works

1. You define your fixtures in a Ruby DSL file
2. Before your test suite runs, FixtureBot generates YAML fixture files
3. Rails loads those fixtures as usual

The generated YAML files are static snapshots you can inspect, diff, and commit. There's no magic at test time — Rails just sees normal fixtures.

## Usage with RSpec

Create `spec/fixtures.rb`:

```ruby
# Generators — these run for every record unless overridden
user.email { "#{name}@example.com" }

# Records
user :brad do
  name "Brad"
  email "brad@example.com"
end

user :alice do
  name "Alice"
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
```

Add a `bin/fixturebot` binstub (or use `bundle exec fixturebot`):

```bash
bundle binstubs fixturebot-rails
```

Generate fixtures before running specs by adding this to your `Rakefile`:

```ruby
task :spec => "fixturebot:generate"
```

Or run it explicitly:

```bash
bundle exec fixturebot generate spec/fixtures.rb spec/fixtures
```

This reads your database schema, evaluates `spec/fixtures.rb`, and writes YAML files to `spec/fixtures/`:

```
spec/fixtures/
  users.yml
  posts.yml
  tags.yml
  posts_tags.yml
```

Then run your specs as normal:

```bash
bundle exec rspec
```

Rails loads the YAML fixtures automatically. Use them in your tests like any other fixture:

```ruby
RSpec.describe Post, type: :model do
  fixtures :all

  it "belongs to an author" do
    post = posts(:hello_world)
    expect(post.author).to eq(users(:brad))
  end
end
```

## Usage with Minitest

Create `test/fixtures.rb`:

```ruby
user.email { "#{name}@example.com" }

user :brad do
  name "Brad"
  email "brad@example.com"
end

user :alice do
  name "Alice"
end

post :hello_world do
  title "Hello World"
  body "Welcome to the blog!"
  author :brad
end
```

Generate fixtures before running tests by adding this to your `Rakefile`:

```ruby
task :test => "fixturebot:generate"
```

Or run it explicitly:

```bash
bundle exec fixturebot generate test/fixtures.rb test/fixtures
```

Then run your tests as normal:

```bash
bundle exec rails test
```

Use fixtures in your tests like you always have:

```ruby
class PostTest < ActiveSupport::TestCase
  def test_belongs_to_author
    post = posts(:hello_world)
    assert_equal users(:brad), post.author
  end
end
```

## The DSL

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

### Generators

Set default values for columns. The block runs for each record and has access to the record name:

```ruby
user.email { "#{name}@example.com" }
```

If a record sets a literal value for that column, it shadows the generator:

```ruby
user.email { "#{name}@example.com" }

user :brad do
  name "Brad"           # generator sees name as "Brad", not "brad"
  email "brad@hey.com"  # literal — skips the generator entirely
end

user :alice do
  name "Alice"
  # email generated as "Alice@example.com"
end
```

### Records

Define named records with literal column values:

```ruby
user :brad do
  name "Brad"
  email "brad@example.com"
end
```

Records without a block get an auto-generated ID and any generator defaults:

```ruby
user :alice
# => { id: <stable_id>, email: "alice@example.com" }
```

### Associations

Reference other records by name for `belongs_to`:

```ruby
post :hello_world do
  title "Hello World"
  author :brad  # sets author_id to brad's stable ID
end
```

### Join tables (HABTM)

Reference multiple records for join table associations:

```ruby
post :hello_world do
  title "Hello World"
  tags :ruby, :rails  # creates rows in posts_tags
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

Try the playground without Rails:

```bash
bundle exec exe/fixturedump show ./playground/blog
```
