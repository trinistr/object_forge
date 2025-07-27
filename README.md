# ObjectForge

> [!TIP]
> You may be viewing documentation for an older (or newer) version of the gem than intended. Look at [Changelog](https://github.com/trinistr/object_forge/blob/main/CHANGELOG.md) to see all versions, including unreleased changes.

<!-- Latest: [![Gem Version](https://badge.fury.io/rb/object_forge.svg?icon=si%3Arubygems)](https://rubygems.org/gems/object_forge) -->
[![CI](https://github.com/trinistr/object_forge/actions/workflows/CI.yaml/badge.svg)](https://github.com/trinistr/object_forge/actions/workflows/CI.yaml)

***

ObjectForge provides a familiar way to build objects in any context with minimal assumptions about usage environment. It has no connection to any framework and, indeed, has nothing to do with a database. To use, just define some factories and call them wherever you need, be it in tests, console, or application code.

## Installation

Add to your application's Gemfile:

```ruby
gem "object_forge", github: "trinistr/object_forge"
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests, `rake rubocop` to lint code and check style compliance, `rake rbs` to validate signatures or just `rake` to do everything above. There is also `rake steep` to check typing, and `rake docs` to generate YARD documentation.

You can also run `bin/console` for an interactive prompt that will allow you to experiment, or `bin/benchmark` to run a benchmark script and generate a StackProf flamegraph.

To install this gem onto your local machine, run `rake install`. To release a new version, run `rake version:{major|minor|patch}`, and then run `rake release`, which will push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trinistr/object_forge.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
