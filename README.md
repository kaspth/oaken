# Oaken

The gem we're building in the Open Source Retreat https://kaspthrb.gumroad.com/l/open-source-retreat-summer-2023

## Installation

TODO: Replace with private package install instructions.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add oaken

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install oaken

## Features

### Fixture to Seed Converter

You can now use Oaken to easily convert your Rails fixtures to seedable models. To utilize this feature, run the following command:

    $ rails generate oaken:fixture_converter

This will convert `users.yml` to `users.rb`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kaspth/oaken. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kaspth/oaken/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Oaken project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/kaspth/oaken/blob/main/CODE_OF_CONDUCT.md).

## Support

Initial development is supported in part by:

<a href="https://arrows.to">
 <img src="https://user-images.githubusercontent.com/56947/258236465-06c692a7-738e-44bd-914e-fecc697317ce.png" />
</a>

And by:

- [Alexandre Ruban](https://github.com/alexandreruban)
- [Lars Kronfält](https://github.com/larkro)

As a sponsor you're welcome to submit a pull request to add your own name here.
