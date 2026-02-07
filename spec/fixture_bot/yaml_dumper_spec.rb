# frozen_string_literal: true

require "tmpdir"
require "yaml"

RSpec.describe FixtureBot::YamlDumper do
  let(:schema) do
    FixtureBot::Schema.define do
      table :users, columns: [:name, :email]
      table :posts, columns: [:title, :author_id] do
        belongs_to :author, table: :users
      end
    end
  end

  let(:fixture_set) do
    FixtureBot.define(schema) do
      user :admin do
        name "Brad"
        email "brad@blog.test"
      end

      post :hello do
        title "Hello"
        author :admin
      end
    end
  end

  let(:dumper) { described_class.new(fixture_set) }

  describe "#dump_table" do
    it "produces valid YAML with string keys" do
      yaml = dumper.dump_table(:users)
      parsed = YAML.safe_load(yaml)

      expect(parsed).to have_key("admin")
      expect(parsed["admin"]["name"]).to eq("Brad")
      expect(parsed["admin"]["email"]).to eq("brad@blog.test")
      expect(parsed["admin"]["id"]).to be_a(Integer)
    end
  end

  describe "#dump" do
    it "writes per-table YAML files to the output directory" do
      dir = Dir.mktmpdir
      begin
        dumper.dump(dir)

        expect(File.exist?(File.join(dir, "users.yml"))).to be true
        expect(File.exist?(File.join(dir, "posts.yml"))).to be true

        users = YAML.safe_load(File.read(File.join(dir, "users.yml")))
        expect(users["admin"]["name"]).to eq("Brad")

        posts = YAML.safe_load(File.read(File.join(dir, "posts.yml")))
        expect(posts["hello"]["title"]).to eq("Hello")
        expect(posts["hello"]["author_id"]).to eq(users["admin"]["id"])
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "skips empty tables" do
      dir = Dir.mktmpdir
      begin
        # Define a fixture set with only users, no posts
        fs = FixtureBot.define(schema) do
          user :admin do
            name "Brad"
            email "brad@test.com"
          end
        end

        described_class.new(fs).dump(dir)

        expect(File.exist?(File.join(dir, "users.yml"))).to be true
        expect(File.exist?(File.join(dir, "posts.yml"))).to be false
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end
end
