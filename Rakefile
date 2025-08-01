# frozen_string_literal: true

task default: %i[spec rubocop steep]

require "English"
require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # Well, this is bad, but we can live without it.
  task :rubocop do
    puts "RuboCop is not available, linting will not be done!"
  end
end

desc "Validate signatures with RBS"
task :rbs do
  puts "Checking signatures with RBS..."
  if system "rbs", "-Isig", "validate"
    puts "Signatures are valid!"
    puts
  else
    puts "Signatures validation was not successful!"
    puts
    exit $CHILD_STATUS.exitstatus || 1
  end
end

desc "Validate code typing with Steep"
task steep: :rbs do
  status = system "steep", "check"
  exit $CHILD_STATUS.exitstatus || 1 unless status
end

desc "Generate documentation with YARD"
task :docs do
  status = system "yard", "doc", ".", "--tag", "thread_safety:Thread safety"
  exit $CHILD_STATUS.exitstatus || 1 unless status
end

namespace :version do
  desc "Bump major version"
  task :major do
    Rake::Task["version:_update_version"].invoke("major")
  end

  desc "Bump minor version"
  task :minor do
    Rake::Task["version:_update_version"].invoke("minor")
  end

  desc "Bump patch version"
  task :patch do
    Rake::Task["version:_update_version"].invoke("patch")
  end

  task :_update_version, [:bump] do |_task, args| # rubocop:disable Rake/Desc
    require "bump"
    Bump::Bump.run(args[:bump], commit: false, changelog: true)

    name = Dir["*.gemspec"].first.then { |f| Gem::Specification.load(f).name }
    new_version = Bump::Bump.current
    Rake::Task["version:_update_changelog"].invoke(name, new_version)
    Rake::Task["version:_commit_and_tag"].invoke(name, new_version)
  end

  task :_update_changelog, [:name, :new_version] do |_task, args| # rubocop:disable Rake/Desc
    name = args[:name]
    new_version = args[:new_version]

    changelog = File.read("CHANGELOG.md").split(/(^(?>##+)[^\n]+\n\n)/)
    # Change previous comparison link
    prev_index = changelog.index { _1.match?(/^## \[v#{new_version}\]/) }
    changelog[prev_index + 1].gsub!("...main", "...v#{new_version}") if prev_index
    # Add new comparison link
    next_index = changelog.index { _1.match?(/^## \[Next\]/) }
    changelog[next_index] <<
      "\n[Compare v#{new_version}...main](https://github.com/trinistr/#{name}/compare/v#{new_version}...main)\n\n"
    # Add a version link
    changelog.last.sub!(
      /\[Next\]: .+/,
      "\\0\n[v#{new_version}]: https://github.com/trinistr/#{name}/tree/v#{new_version}"
    )
    # Delete v0.0.0 if present
    changelog.delete_if { _1.match?(/^## \[v0\.0\.0\]/) }

    File.write("CHANGELOG.md", changelog.join)
  end

  task :_commit_and_tag, [:name, :new_version] do |_task, args| # rubocop:disable Rake/Desc
    name = args[:name]
    new_version = args[:new_version]

    %W[CHANGELOG.md Gemfile.lock lib/#{name}/version.rb].each do |f|
      system("git", "add", "--update", f)
    end
    system("git", "commit", "-m", "v#{new_version}")
    system("git", "tag", "-s", "-m", "v#{new_version}", "v#{new_version}")
  end
end
