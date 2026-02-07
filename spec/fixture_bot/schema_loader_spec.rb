# frozen_string_literal: true

require "fixture_bot/rails"
require "tmpdir"

RSpec.describe FixtureBot::Rails::SchemaLoader do
  let(:schema_content) do
    <<~RUBY
      ActiveRecord::Schema.define(version: 2024_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "name"
          t.string "email"
          t.timestamps
        end

        create_table "posts", force: :cascade do |t|
          t.string "title"
          t.text "body"
          t.integer "author_id"
          t.timestamps
        end

        add_foreign_key "posts", "users", column: "author_id"

        create_table "tags", force: :cascade do |t|
          t.string "name"
          t.timestamps
        end

        create_table "posts_tags", id: false, force: :cascade do |t|
          t.integer "post_id", null: false
          t.integer "tag_id", null: false
        end
      end
    RUBY
  end

  let(:schema_path) do
    dir = Dir.mktmpdir
    path = File.join(dir, "schema.rb")
    File.write(path, schema_content)
    path
  end

  after do
    FileUtils.rm_rf(File.dirname(schema_path))
  end

  subject(:schema) { described_class.load_file(schema_path) }

  it "loads regular tables with columns" do
    expect(schema.tables.keys).to contain_exactly(:users, :posts, :tags)
  end

  it "skips id, created_at, updated_at columns" do
    expect(schema.tables[:users].columns).to contain_exactly(:name, :email)
    expect(schema.tables[:posts].columns).to contain_exactly(:title, :body, :author_id)
    expect(schema.tables[:tags].columns).to contain_exactly(:name)
  end

  it "detects belongs_to associations from foreign keys" do
    associations = schema.tables[:posts].belongs_to_associations
    expect(associations.size).to eq(1)
    expect(associations.first.name).to eq(:author)
    expect(associations.first.table).to eq(:users)
    expect(associations.first.foreign_key).to eq(:author_id)
  end

  it "detects join tables" do
    expect(schema.join_tables.keys).to contain_exactly(:posts_tags)
    jt = schema.join_tables[:posts_tags]
    expect(jt.left_table).to eq(:posts)
    expect(jt.right_table).to eq(:tags)
    expect(jt.left_foreign_key).to eq(:post_id)
    expect(jt.right_foreign_key).to eq(:tag_id)
  end

  it "does not include join tables in regular tables" do
    expect(schema.tables).not_to have_key(:posts_tags)
  end
end
