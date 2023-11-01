# Oaken

Oaken is an alternative to fixtures and/or factories to manage your development, test and some production data using data scripts.

## Setup

### Starting in development

You can set it up in `db/seeds.rb`, like this:

```ruby
Oaken.prepare do
  seed :accounts, :data
end
```

This will look for deeply nested files to load in `db/seeds` and `db/seeds/#{Rails.env}` within the `accounts` and `data` directories.

Here's what they could look like.

```ruby
# db/seeds/accounts/kaspers_donuts.rb
donuts = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper = users.create :kasper, name: "Kasper"
administratorships.create account: donuts, user: kasper

coworker = users.create :coworker, name: "Coworker"
administratorships.create account: donuts, user: coworker

menu = menus.create account: donuts
plain_donut = menu_items.create menu: menu, name: "Plain", price_cents: 10_00
sprinkled_donut = menu_items.create menu: menu, name: "Sprinkled", price_cents: 10_10

supporter = users.create name: "Super Supporter"
orders.insert_all [user_id: supporter.id, item_id: plain_donut.id] * 10

orders.insert_all \
  10.times.map { { user_id: users.create(name: "Customer #{_1}").id, item_id: menu.items.sample.id } }
```

```ruby
# db/seeds/data/plans.rb
plans.insert :basic, title: "Basic", price_cents: 10_00
```

Seed files will generally use `create` and/or `insert`. Passing a symbol to name the record is useful when reusing the data in tests.

Now you can run `bin/rails db:seed` — plus Oaken skips executing a seed file if it knows the file hasn't been changed since the last seeding. Speedy!

### Interlude: Directory Naming Conventions

Oaken has some chosen directory conventions to help strengthen your understanding of your object graph:

- Have a directory for your top-level model, like `Account`, `Team`, `Organization`, that's why we have `db/seeds/accounts` above.
- `db/seeds/data` for any data tables, like the plans a SaaS app has.
- `db/seeds/tests/cases` for any specific cases that are only used in some tests, like `pagination.rb`.

### Reusing data in tests

With the setup above, Oaken can reuse the same data in tests like so:

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  include Oaken.seeds

  # Override Minitest::Test#run to wrap each test in a transaction.
  def run
    result = nil
    ActiveRecord::Base.transaction(requires_new: true) do
      result = super
      raise ActiveRecord::Rollback
    end
    result
  end
end
```

Now tests have access to `accounts.kaspers_donuts` and `users.kasper` etc. that were setup in the data scripts.

You can also load a specific seed, like this:

```ruby
class PaginationTest < ActionDispatch::IntegrationTest
  seed "cases/pagination"
end
```

### Resetting cache

Oaken is still early days, so you may need to reset the cache that skips seed files. Pass `OAKEN_RESET` to clear it:

```sh
OAKEN_RESET=1 bin/rails db:seed
OAKEN_RESET=1 bin/rails test
```

### Fixtures Converter

You can convert your Rails fixtures to Oaken's seeds by running:

    $ bin/rails generate oaken:convert:fixtures

This will convert anything in test/fixtures to db/seeds. E.g. `test/fixtures/users.yml` becomes `db/seeds/users.rb`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add oaken

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install oaken

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `cd test/dummy` and `bin/rails test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

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
- [Manuel Costa Reis](https://github.com/manuelfcreis)
- [Thomas Cannon](https://github.com/tcannonfodder)

As a sponsor you're welcome to submit a pull request to add your own name here.
