# Oaken

Oaken is a new take on development and test data management for your Rails app. It blends the stability and storytelling from Fixtures with the dynamicness of FactoryBot/Fabricator.

> But seriously; Oaken is one of the single greatest tools I've added to my belt in the past year
>
> It's made cross-environment shared data, data prepping for demos, edge-case tests, and overall development much more reliable & shareable across a team
> [@tcannonfodder](https://github.com/tcannonfodder)

Fixtures are stable & help you build a story of how your app and its object graph exists along with edge cases, but the UX is unfortunately a nightmare.
To trace N associations, you have to open and read N different files — there's no way to group by scenario.

FactoryBot is spray & pray. You basically say “screw it, just give me the bare minimum I need to run this test”, which slows everything down because there’s no cohesion; and the Factories are always suspect in terms of completeness. Sure, I got the test to pass by wiring these 5 Factories together but did I miss something?

Oaken instead upgrades seeds in `db/seeds.rb`, so that you can put together scenarios & also reuse the development data in tests. That way the data you see in your development browser, is the same data you work with in tests to tie it more together — especially for people who are new to your codebase.

So you get the stability of named keys, a cohesive dataset, and a story like Fixtures. But the dynamics of FactoryBot as well. And unlike FactoryBot, you’re not making tons of one-off records to handle each case.

While Fixtures and FactoryBot both load data & truncate in tests, the end result is you end up writing less data back & forth to the database because you aren’t cobbling stuff together.

## Setup

### Starting in development

You can set it up in `db/seeds.rb`, like this:

```ruby
Oaken.prepare do
  seed :accounts, :data
end
```

This will look for deeply nested files to load in `db/seeds` and `db/seeds/#{Rails.env}` within the `accounts` and `data` directories.

Here's what they could look like:

```ruby
# db/seeds/accounts/kaspers_donuts.rb
donuts = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper   = users.create :kasper,   name: "Kasper",   accounts: [donuts]
coworker = users.create :coworker, name: "Coworker", accounts: [donuts]

menu = menus.create account: donuts
plain_donut     = menu_items.create menu: menu, name: "Plain",     price_cents: 10_00
sprinkled_donut = menu_items.create menu: menu, name: "Sprinkled", price_cents: 10_10

supporter = users.create name: "Super Supporter"
orders.insert_all [user_id: supporter.id, item_id: plain_donut.id] * 10

orders.insert_all \
  10.times.map { { user_id: users.create(name: "Customer #{_1}").id, item_id: menu.items.sample.id } }
```

```ruby
# db/seeds/data/plans.rb
plans.upsert :basic, title: "Basic", price_cents: 10_00
```

Seed files will generally use `create` and/or `insert`. Passing a symbol to name the record is useful when reusing the data in tests.

Now you can run `bin/rails db:seed` and `bin/rails db:seed:replant`.

### Interlude: Directory Naming Conventions

Oaken has some chosen directory conventions to help strengthen your understanding of your object graph:

- Have a directory for your top-level model, like `Account`, `Team`, `Organization`, that's why we have `db/seeds/accounts` above.
- `db/seeds/data` for any data tables, like the plans a SaaS app has.
- `db/seeds/test/cases` for any specific cases that are only used in some tests, like `pagination.rb`.

### Using default attributes

You can set up default attributes that's applied to created/inserted records at different levels, like this:

```ruby
Oaken.prepare do
  # Assign broad global defaults for every type.
  defaults name: -> { Faker::Name.name }, public_key: -> { SecureRandom.hex }

  # Assign a more specific default on one type, which overrides the global default above.
  accounts.defaults name: -> { Faker::Business.name }
end
```

> [!TIP]
> `defaults` are particularly well suited for assigning generated data with [Faker](https://github.com/faker-ruby/faker).

### Reusing data in tests

With the setup above, Oaken can reuse the same data in tests like this:

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  include Oaken::TestSetup
end
```

Now tests have access to `accounts.kaspers_donuts` and `users.kasper` etc. that were setup in the data scripts.

> [!NOTE]
> For RSpec, you can put this in `spec/rails_helper.rb`:
> ```ruby
> require "oaken/rspec_setup"
> ```

You can also load a specific seed, like this:

```ruby
class PaginationTest < ActionDispatch::IntegrationTest
  setup { seed "cases/pagination" }
end
```

And in RSpec:

```ruby
RSpec.describe "Pagination", type: :feature do
  before { seed "cases/pagination" }
end
```

> [!NOTE]
> We're recommending having one-off seeds on an individual unit of work to help reinforce test isolation. Having some seed files be isolated also helps:
>
> - Reduce amount of junk data generated for unrelated tests
> - Make it easier to debug a particular test
> - Reduce test flakiness
> - Encourage writing seed files for specific edge-case scenarios

### Fixtures Converter

You can convert your Rails fixtures to Oaken's seeds by running:

    $ bin/rails generate oaken:convert:fixtures

This will convert anything in test/fixtures to db/seeds. E.g. `test/fixtures/users.yml` becomes `db/seeds/users.rb`.

### Disable fixtures

IF you've fully converted to Oaken you may no longer want fixtures when running Rails' generators,
so you can disable generating them in `config/application.rb` like this:

```ruby
module YourApp
  class Application < Rails::Application
    # We prefer Oaken to fixtures, so we disable them here.
    config.app_generators { _1.test_framework _1.test_framework, fixture: false }
  end
end
```

The `test_framework` repeating is to preserve `:test_unit` or `:rspec` respectively.

> [!NOTE]
> If you're using `FactoryBot` as well, you don't need to do this since it already replaces fixtures for you.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add oaken

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install oaken

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rails test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

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
