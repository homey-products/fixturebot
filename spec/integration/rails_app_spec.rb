# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "open3"
require "yaml"
require "zlib"

RSpec.describe "Rails integration", :integration do
  GEM_ROOT = File.expand_path("../..", __dir__)

  def run_cmd!(cmd, chdir:)
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e(cmd, chdir: chdir)
    end
    unless status.success?
      raise "Command failed: #{cmd}\n#{output}"
    end
    output
  end

  before(:all) do
    @tmpdir = Dir.mktmpdir("fixturebot_integration")
    @app_dir = File.join(@tmpdir, "dummy_app")

    # Create a new minimal Rails app
    run_cmd!("rails new dummy_app --minimal --skip-git --skip-docker --skip-bundle", chdir: @tmpdir)

    # Add fixturebot to Gemfile
    gemfile = File.join(@app_dir, "Gemfile")
    File.open(gemfile, "a") do |f|
      f.puts %(gem "fixturebot-rails", path: "#{GEM_ROOT}", require: "fixturebot/rails")
    end

    # Bundle install
    run_cmd!("bundle install", chdir: @app_dir)

    # Generate models
    run_cmd!("bin/rails generate model Blog title:string --no-fixture", chdir: @app_dir)
    run_cmd!("bin/rails generate model Post title:string blog:references --no-fixture", chdir: @app_dir)
    run_cmd!("bin/rails generate model Tag name:string --no-fixture", chdir: @app_dir)
    run_cmd!("bin/rails generate migration CreateJoinTablePostsTags post tag", chdir: @app_dir)

    # Migrate
    run_cmd!("bin/rails db:migrate", chdir: @app_dir)

    # Install fixturebot
    run_cmd!("bin/rails generate fixturebot:install", chdir: @app_dir)

    # Overwrite fixtures.rb with our test DSL
    File.write(File.join(@app_dir, "test", "fixtures.rb"), <<~RUBY)
      FixtureBot.define do
        blog :tech do
          title "Tech Blog"
        end

        blog :personal do
          title "Personal Blog"
        end

        post :hello do
          title "Hello World"
          blog :tech
          tags :ruby, :rails
        end

        post :goodbye do
          title "Goodbye World"
          blog :personal
        end

        tag :ruby do
          name "Ruby"
        end

        tag :rails do
          name "Rails"
        end
      end
    RUBY

    # Compile fixtures
    run_cmd!("bin/rails fixturebot:compile", chdir: @app_dir)

    # Read compiled YAML files
    fixtures_dir = File.join(@app_dir, "test", "fixtures")
    @blogs_yaml = YAML.safe_load(File.read(File.join(fixtures_dir, "blogs.yml")))
    @posts_yaml = YAML.safe_load(File.read(File.join(fixtures_dir, "posts.yml")))
    @tags_yaml = YAML.safe_load(File.read(File.join(fixtures_dir, "tags.yml")))
    @posts_tags_yaml = YAML.safe_load(File.read(File.join(fixtures_dir, "posts_tags.yml")))
  end

  after(:all) do
    FileUtils.rm_rf(@tmpdir) if @tmpdir
  end

  it "generates blogs.yml with correct records" do
    expect(@blogs_yaml).to have_key("tech")
    expect(@blogs_yaml).to have_key("personal")
    expect(@blogs_yaml["tech"]["title"]).to eq("Tech Blog")
    expect(@blogs_yaml["personal"]["title"]).to eq("Personal Blog")
  end

  it "generates posts.yml with correct records" do
    expect(@posts_yaml).to have_key("hello")
    expect(@posts_yaml).to have_key("goodbye")
    expect(@posts_yaml["hello"]["title"]).to eq("Hello World")
    expect(@posts_yaml["goodbye"]["title"]).to eq("Goodbye World")
  end

  it "resolves blog references to correct IDs" do
    tech_id = Zlib.crc32("blogs:tech") & 0x7FFFFFFF
    personal_id = Zlib.crc32("blogs:personal") & 0x7FFFFFFF

    expect(@posts_yaml["hello"]["blog_id"]).to eq(tech_id)
    expect(@posts_yaml["goodbye"]["blog_id"]).to eq(personal_id)
  end

  it "generates tags.yml with correct records" do
    expect(@tags_yaml).to have_key("ruby")
    expect(@tags_yaml).to have_key("rails")
    expect(@tags_yaml["ruby"]["name"]).to eq("Ruby")
    expect(@tags_yaml["rails"]["name"]).to eq("Rails")
  end

  it "generates posts_tags.yml with correct join rows" do
    hello_id = Zlib.crc32("posts:hello") & 0x7FFFFFFF
    ruby_id = Zlib.crc32("tags:ruby") & 0x7FFFFFFF
    rails_id = Zlib.crc32("tags:rails") & 0x7FFFFFFF

    rows = @posts_tags_yaml.values
    post_ids = rows.map { |r| r["post_id"] }.uniq
    tag_ids = rows.map { |r| r["tag_id"] }.sort

    expect(post_ids).to eq([hello_id])
    expect(tag_ids).to contain_exactly(ruby_id, rails_id)
  end

  it "produces deterministic IDs via Zlib.crc32" do
    expect(@blogs_yaml["tech"]["id"]).to eq(Zlib.crc32("blogs:tech") & 0x7FFFFFFF)
    expect(@blogs_yaml["personal"]["id"]).to eq(Zlib.crc32("blogs:personal") & 0x7FFFFFFF)
    expect(@posts_yaml["hello"]["id"]).to eq(Zlib.crc32("posts:hello") & 0x7FFFFFFF)
    expect(@tags_yaml["ruby"]["id"]).to eq(Zlib.crc32("tags:ruby") & 0x7FFFFFFF)
  end

  it "injects require into test_helper.rb" do
    test_helper = File.read(File.join(@app_dir, "test", "test_helper.rb"))
    expect(test_helper).to include('require "fixturebot/minitest"')
  end

  it "creates YAML files for all tables" do
    fixtures_dir = File.join(@app_dir, "test", "fixtures")
    expect(File.exist?(File.join(fixtures_dir, "blogs.yml"))).to be true
    expect(File.exist?(File.join(fixtures_dir, "posts.yml"))).to be true
    expect(File.exist?(File.join(fixtures_dir, "tags.yml"))).to be true
    expect(File.exist?(File.join(fixtures_dir, "posts_tags.yml"))).to be true
  end
end
