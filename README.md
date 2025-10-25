# Oaken

Oaken is fixtures + factories + seeds for your Rails development & test environments.

You may want to head straight to the [examples](examples) directory.

## Oaken is like fixtures, without the nightmare UX

Oaken takes inspiration from Rails' fixtures' approach of storytelling about your app's object graph, but replaces the nightmare YAML-based UX with Ruby-based data scripts. This makes data much easier to reason about & connect the dots.

In Oaken, you start by creating a root-level model, typically an Account, Team, or Organization etc. to group everything on, in a scenario. From your root-level model, you then start building your object graph by mirroring how your app works.

So what comes next in your account flow? Maybe it's creating Users on the account.

You can go further if you need to. Is the Account about selling something, like donuts? Maybe you add a menu and some items.

It'll look like this:

```ruby
account = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper   = users.create :kasper,   name: "Kasper",   email_address: "kasper@example.com",   accounts: [account]
coworker = users.create :coworker, name: "Coworker", email_address: "coworker@example.com", accounts: [account]

menu = menus.create(account:)
plain_donut     = menu_items.create menu:, name: "Plain",     price_cents: 10_00
sprinkled_donut = menu_items.create menu:, name: "Sprinkled", price_cents: 10_10
```

> [!NOTE]
> `create` takes an optional symbol label. This makes the record accessible in tests, e.g. `users.create :kasper` lets tests do `setup { @kasper = users.kasper }`.

With fixtures, this would be 4 different files in `test/fixtures` for `accounts`, `users`, `menus`, and `menu_items`. It would be ~20 lines of YAML versus ~6 lines of Ruby for this data.

Another issue in fixture files, is that objects from different scenarios are all mixed together making it hard to get a picture of what's going on — even in small apps.

Fixtures also require you to label every record and make them unique throughout your dataset — you have to be careful not to create clashes. This gets difficult to manage quickly and requires diligence on a team that's trying to ship.

However, often the fact that a record is associated onto another is enough. So in Oaken, we let you skip naming every record. Notice how the `menus.create` & `menu_items.create` calls don't pass symbol labels. You can still get at them in tests though if you really need to with `accounts.kaspers_donuts.menus.first.menu_items.first`.

<details>
  <summary>See the fixtures version</summary>

```yaml
# test/fixtures/accounts.yml
kaspers_donuts:
  name: Kasper's Donuts

# test/fixtures/users.yml
kasper:
  name: "Kasper"
  email_address: "kasper@example.com"
  accounts: kaspers_donuts

coworker:
  name: "Coworker"
  email_address: "coworker@example.com"
  accounts: kaspers_donuts

# test/fixtures/menus.yml
basic:
  account: kaspers_donuts

# test/fixtures/menu/items.yml
plain_donut:
  menu: basic
  name: Plain
  price_cents: 10_00

sprinkled_donut:
  menu: basic
  name: Sprinkled
  price_cents: 10_10
```

</details>

### Oaken is like fixtures, we seed data before tests run

The reason you go through all the trouble of massaging your fixture files is to have a stable named dataset across test runs that's relatively quick to load — so the database call cost is amortized across tests.

Oaken mirrors this approach giving you stability in your dataset and the relative quickness to insert the data.

For instance, if you have 10 tests that each need the same 2 records, Oaken puts them in the database once before tests run, same as fixtures.

The tradeoff is that if you run just 1 test we'll still seed those 2 same records, but we'll also seed any other record you've added to the shared dataset that might not be needed in those tests.

We rely on Rails' tests being wrapped in transactions so any changes are rolled back after the test case run.

> [!NOTE]
> It can be a good idea to structure your object graph so you won't need database records for your tests — reality can sometimes be far from that ideal state though. Oaken aims to make your present reality easier and something you can improve.

## Oaken is unlike factories, focusing on shared datasets

Factories can let you start an app easier. It's just this one factory for now, ok, easy enough.

Over time, however, many teams find their factory based test suite slows to a crawl. Suddenly one factory ends up pulling in the rest of the app.

Factories end up requiring a lot of diligence and passing just the right things in just-so to make managable.

Oaken does away with this. See the sections on the fixtures comparisons above for how.

> [!WARNING]
> Full Disclaimer: while I have worked on systems using factories, I overall don't get it and the fixtures approach makes more sense to me despite the UX issues. I'm trying to support a partial factories approach here in Oaken, see the below section for that, and I'm open to ideas here.

> [!TIP]
> Oaken is compatible with FactoryBot and Fabrication, and they should be able to work together. I consider it a bug if there's compatibility issues, so please open an issue here if you find something.

### Oaken is like factories, with dynamic defaults & helper methods

See the sections on defaults & helpers below.

The aim for Oaken is to have most of the feature set of factories for a fraction of the implementation complexity.

## Oaken gives db/seeds.rb superpowers

Oaken upgrades seeds in `db/seeds.rb`, so you can put together scenarios & reuse the development data in tests.

This way, the data you see in your browser, is the same data you work with in tests to make your object graph easier to get — especially for people new to your codebase.

So you get a cohesive & stable dataset with a story like fixtures & their fast loading. But you also get the dynamics of FactoryBot/Fabrication as well without making tons of one-off records to handle each case.

The end result is you end up writing less data back & forth to the database because you aren’t cobbling stuff together.

## Praise from users

> But seriously; Oaken is one of the single greatest tools I've added to my belt in the past year
>
> It's made cross-environment shared data, data prepping for demos, edge-case tests, and overall development much more reliable & shareable across a team
>
> [@tcannonfodder](https://github.com/tcannonfodder)

> Thanks for this wonderful project! My head doesn't grok factories and I just want vanilla Rails testing with something better than fixtures, and this is so much better.
>
> The default YAML fixtures is somehow both too simple and too convoluted. It's hard to reference complex associations with it, and the fact that the data gets spread across many files makes it hard to read and harder to grasp.
>
> Oaken, on the other hand, is closer to using the console, which we already know, only in a repeatable and tidier way. The testing data/seeds setup process just feels more intentional this way.
>
> [@evenreven](https://github.com/evenreven)

## Design goals

### Consistent data & constrained Ruby

We're using `accounts.create` and such instead of `Account.create!` to help enforce consistency & constrain your Ruby usage. This also allows for extra features like `defaults` and helpers that take way less to implement.

### Pick up in 1 hour or less

We don't want to be a costly DSL that takes ages to learn and relearn when you come back to it.

We're aiming for a time-to-understand of less than an hour. Same goes for the internals, if you dive in, it should ideally take less than 1 hour to comprehend most of it.

### Similar ideas to Pkl

We share similar [sentiments to the Pkl configuration language](https://pkl-lang.org/main/current/introduction/comparison.html). You may find the ideas helpful before using Oaken.

Oddly enough Oaken came out before Pkl, I just read the ideas here and went "yes, exactly!"

## Setup

### Loading directories/files

By default, `Oaken.loader` returns an `Oaken::Loader` instance to handle loading seed files.

You can load a seed directory via `Oaken.loader.seed`. You can also load a file, it'll technically just be a match that happens to only hit one file.

So if you call `Oaken.loader.seed :accounts`, we'll look within `db/seeds/` and `db/seeds/#{Rails.env}/` and match `accounts{,**/*}.rb`. So these files would be found:

- accounts.rb
- accounts/kaspers_donuts.rb
- accounts/kaspers_donuts/deeply/nested/path.rb
- accounts/demo.rb
- and so on.

> [!TIP]
> You can call `Oaken.loader.glob` with a single identifier to see what files we'll match. > Some samples: `Oaken.loader.glob :accounts`, `Oaken.loader.glob "cases/pagination"`.

> [!TIP]
> Putting a file in the top-level `db/seeds` versus `db/seeds/development` or `db/seeds/test` means it's shared in both environments. See below for more tips.

Any directories and/or single-file matches are loaded in the order they're specified. So `loader.seed :setup, :accounts` would first load setup and then accounts.

> [!IMPORTANT]
> Understanding and making effective use of Oaken's directory loading will pay dividends for your usage. You generally want to have 1 top-level directive `seed` call to dictate how seeding happens in e.g. `db/seeds.rb` and then let individual seed files load in no specified order within that.

#### Using the `setup` phase

When you call `Oaken.loader.seed` we'll also call `seed :setup` behind the scenes, though we'll only call this once. It's meant for common setup, like `defaults` and helpers.

> [!IMPORTANT]
> We recommend you don't use `create`/`upsert` directly in setup. Add the `defaults` and/or helpers that would be useful in the later seed files.

Here's some files you could add:

- db/seeds/setup.rb — particularly useful as a starting point.
- db/seeds/setup/defaults.rb — loader and type-specific defaults.
- db/seeds/setup/defaults/*.rb — you could split out more specific files.
- db/seeds/setup/users.rb — a type specific file for its defaults/helpers, doesn't have to just be users.

- db/seeds/development/setup.rb — some defaults/helpers we only want in development.
- db/seeds/test/setup.rb — some defaults/helpers we only want in test.

> [!TIP]
> Remember, since we're using `seed` internally you can nest as deeply as you want to structure however works best. There's tons of flexibility in the `**/*` glob pattern `seed` uses.

#### Directory recommendations & file tips

Oaken has some directory recommendations to help strengthen your understanding of your object graph:

- `db/seeds/data` for any data tables, like the plans a SaaS app has.
- Group scenarios around your top-level root model, like `Account`, `Team`, or `Organization` and have a `db/seeds/accounts` directory.
- `db/seeds/cases` for any specific cases, like pagination.

If you follow all these conventions you could do this:

```ruby
Oaken.loader.seed :data, :accounts, :cases
```

And here's some potential file suggestions you could take advantage of:

- db/seeds/data/plans.rb — put your SaaS plans in here.
- db/seeds/test/data/plans.rb — some test specific plans, in case we need them.

- db/seeds/cases/pagination.rb — group the seed code for generating pagination data here. NOTE: this could reference an account setup earlier.
- db/seeds/test/cases/*.rb — any test specific cases.

> [!TIP]
> We're letting Oaken's loading do all the hard work here, we're just staging the loading phases by specifying the top-level order.

##### Loading specific cases in tests only

For the cases part, you may want to tweak it a bit more.

You could add any definitely shared cases in `db/seeds/cases`. Say you have a `db/seeds/cases/pagination.rb` case that can be shared between development and test.

If not, you can add environment specific ones in `db/seeds/development/cases/pagination.rb` and `db/seeds/test/cases/pagination.rb`.

You could also avoid loading all the cases in the test environment like this:

```ruby
Oaken.loader.seed :cases if Rails.env.development?
```

Now you can load specific seeds in tests, like this:

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

#### Configuring loaders

You can customize the loading and loader as well:

```ruby
# config/initializers/oaken.rb
# Call `with` to build a new loader. Here we're just passing the default internal options:
loader = Oaken.loader.with(lookup_paths: "test/seeds") # Useful to pull from another directory, when migrating.
loader = Oaken.loader.with(locator: Oaken::Loader::Type, provider: Oaken::Stored::ActiveRecord, context: Oaken::Seeds)

Oaken.loader = loader # You can also replace Oaken's default loader.
```

> [!TIP]
> `Oaken` delegates `Oaken::Loader`'s public instance methods to `loader`,
> so `Oaken.seed` works and is really `Oaken.loader.seed`. Same goes for `Oaken.lookup_paths`, `Oaken.with`, `Oaken.glob` and more.

#### In db/seeds.rb

Call `loader.seed` and it'll follow the rules mentioned above:

```ruby
# db/seeds.rb
Oaken.loader.seed :setup, :accounts, :data
Oaken.seed :setup, :accounts, :data # Or just this for short.
```

Both `bin/rails db:seed` and `bin/rails db:seed:replant` work as usual.

#### In the console

If you're in the `bin/rails console`, you can invoke the same `seed` method as in `db/seeds.rb`.

```ruby
Oaken.seed :setup, "cases/pagination"
```

This is useful if you're working on hammering out a single seed script.

> [!TIP]
> Oaken wraps each file load in an `ActiveRecord::Base.transaction` so any invalid data rolls back the whole file.

#### In tests & specs

If you're using Rails' default minitest-based tests call this:

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  include Oaken.loader.test_setup
end
```

We've got full support for Rails' test parallelization out of the box.

> [!NOTE]
> For RSpec, you can put this in `spec/rails_helper.rb`:
> ```ruby
> require "oaken/rspec_setup"
> ```

### Writing Seed Data Scripts

Oaken's data scripts are composed of table name looking methods corresponding to Active Record classes, which you can enhance with `defaults` and helper methods, then eventually calling `create` or `upsert` on them.

#### Loading within the `context` module

Oaken loads every seed file within the context of its `context` module. You can see it with `Oaken.loader.context`, or `Oaken.context` for short.

#### Automatic & manual registry

> [!IMPORTANT]
> Ok, this bit is probably the most complex part in Oaken. You can see the implementation in `Oaken::Seeds#method_missing` and then `Oaken::Loader::Type`.

When you reference e.g. `accounts` we'll hit `Oaken::Seeds#method_missing` hook and:

- locate a class using `loader.locate`, hitting `Oaken::Loader::Type.locate`.
- If there's a match, call `loader.register Account, as: :accounts`.
- `loader.register` defines the `accounts` method on the `Oaken.loader.context` module, pointing to an instance of `Oaken::Stored::ActiveRecord`.

We'll respect namespaces up to 3 levels deep, so we'll try to match:

- `menu_items` to `Menu::Item` or `MenuItem`.
- `menu_item_details` to `Menu::Item::Detail`, `MenuItem::Detail`, `Menu::ItemDetail`, `MenuItemDetail`.
- The third level which is going to be 2 separators ("::" or "") to the power of 3 levels, in other words 8 possible constants.

You can skip this by calling `loader.register Menu::Item`, which we'll derive the method name via `name.tableize.tr("/", "_")` or you can call `register Menu::Item, as: :something_else` to have it however you want.

#### `create`

Internally, `create` calls `ActiveRecord::Base#create!` to fail early & prevent invalid records in your dataset. Runs create/save model callbacks.

```ruby
users.create name: "Someone"
```

Some records have uniqueness constraints, like a User's `email_address`, you can pass that via `unique_by`:

```ruby
users.create unique_by: :email_address, name: "First",  email_address: "someone@example.com"
users.create unique_by: :email_address, name: "Second", email_address: "someone@example.com"
```

In the case of a uniqueness constraint clash, we'll `update!` the record, so here `name` is `"Second"`. Runs save/update model callbacks.

> [!IMPORTANT]
> We're trying to make `db:seed` rerunnable incrementally without needing to start from scratch. That's what the `update!` part is for. I'm still not entirely sure about it and I'm trying to figure out a better way to highlight what's going on to users.

#### `upsert`

Mirrors `ActiveRecord::Base#upsert`, allowing you to pass a `unique_by:` which must correspond to a unique database index. Does not run model callbacks.

We'll instantiate and `validate!` the record to help prevent bad data hitting the database.

Typically used for data tables, like so:

```ruby
# db/seeds/data/plans.rb
plans.upsert :basic, unique_by: :title, title: "Basic", price_cents: 10_00
```

#### Using `defaults`

You can set `defaults` that're applied on `create`/`upsert`, like this:

```ruby
# Assign loader-level defaults that's applied to every type.
# Records only include defaults on attributes they have. So only records with a `public_key` attribute receive that and so on.
loader.defaults name: -> { Faker::Name.name }, public_key: -> { SecureRandom.hex }

# Assign specific defaults on one type, which overrides the loader `name` default from above.
accounts.defaults name: -> { Faker::Business.name }, status: :active

accounts.create # `name` comes from the `accounts.defaults` and `public_key` from `loader.defaults`.
accounts.upsert # Same.

users.create # `name` comes from `loader.defaults`.
```

> [!TIP]
> It's best to be explicit in your dataset to tie things together with actual names, to make your object graph more cohesive. However, sometimes attributes can be filled in with [Faker](https://github.com/faker-ruby/faker) if they're not part of the "story".

#### Using `proxy`

`proxy` lets you wrap and delegate scopes from the underlying record.

So if you have this Active Record:

```ruby
class User < ApplicationRecord
  enum :role, %w[admin mod plain].index_by(&:itself)

  scope :cool, -> { where(cool: true) }
end
```

You can then proxy the scopes and use them like this:

```ruby
users.proxy :admin, :mod, :plain
users.proxy :cool

users.create       # Has `role: "plain"`, assuming it's the default role.
users.admin.create # Has `role: "admin"`
users.mod.create   # Has `role: "mod"`
users.cool.create  # Has `cool: true`

# Chaining also works:
users.cool.admin.create # Has `cool: true, role: "admin"`
```

#### Defining helpers

Oaken uses Ruby's [`singleton_methods`](https://rubyapi.org/3.4/o/object#method-i-singleton_methods) for helpers because it costs us 0 lines of code to write and maintain.

> [!NOTE]
> It's still early days for these kind of helpers, so I'm still finding out what's possible with them. I'd love to know how you're using them on the Discussions tab.

In plain Ruby, they look like this:

```ruby
obj = Object.new
def obj.hello = :yo
obj.hello # => :yo
obj.singleton_methods # => [:hello]
```

So you can do stuff like this on, say, a `users` instance:

```ruby
# Notice how we're using the `labeled_email` helper to compose `create_labeled` too:
def users.create_labeled(label, email_address: labeled_email(label), **) = create(label, email_address:, **)
def users.labeled_email(label) = "#{label}@example.com" # You don't have to use endless methods, they're fun though.
```

Now `create_labeled` & `labeled_email` are available everywhere the `users` instance is, in development and test!

```ruby
test "we definitely need this" do
  assert_equal "person@example.com", users.labeled_email(:person)
end
```

##### Providing `unique_by` everywhere

Here's how you can provide a default `unique_by:` on all `users`:

```ruby
# We override the built-in `create` to provide the default. Yes, `super` works on overriden methods!
def users.create(label = nil, unique_by: :email_address, **) = super
```

You could use this to provide `FactoryBot`-like helpers. Maybe adding a `factory` method?

##### Accessing other seeds via `context`

You can access other seeds from within a helper by going through `Oaken.loader.context`/`Oaken.context`. We've got a shorthand so you can just write `context`, like this:

```ruby
users.create :kasper, name: "Kasper"
def users.labeled_email(label) = "#{label}@example.com" # You don't have to use endless methods, they're fun though.

def accounts.some_helper
  context.users.kasper # Access the created named user.
  context.users.labeled_email(:person) # You can also use helpers.
end
```

#### Using `with` to group setup

`with` allows you to group similar `create`/`upsert` calls & apply scoped defaults.

##### `with` during setup

During seeding setup, use `with` in the block form to group `create`/`upsert` calls, typically by an association you want to highlight.

In this example, we're grouping menu items by their menu. We could write out each menu item `create` one by one and pass the menus explicitly just fine.

However, grouping by the menu gets us an extra level of indentation to help reveal our intent.

```ruby
menu_items.with menu: menus.basic do
  it.create :plain_donut, name: "Plain Donut"
  it.create name: "Another Basic Donut"
  # More `create` calls, which automatically go on the basic menu.
end

menu_items.with menu: menus.premium do
  it.create :premium_donut, name: "Premium Donut"
  # Other premium menu items.
end
```

##### `with` in tests

In tests `with` is also useful in the non-block form to apply more explicit scoped defaults used throughout the tests:

```ruby
setup do
  @menu_items = menu_items.with menu: accounts.kaspers_donuts.menus.first, description: "Indulgent & delicious."
end

test "something" do
  @menu_items.create # The menu item is created with the defaults above.
  @menu_items.create menu: menus.premium # You can still override defaults like usual.
end
```

##### How `with` scoping works

To make this easier to understand, we'll use a general `menu_items` object and then a scoped `basic_items = menu_items.with menu: menus.basic` object.

- Labels: go to the general object, `basic_items.create :plain_donut` will be reachable via `menu_items.plain_donut`.
- Defaults: only stay on the `with` object, so `menu_items.create` won't set `menu: menus.basic`, but `basic_items.create` will.
- Helper methods: any helper methods defined on `menu_items` can be called on `basic_items`. We recommend only defining helper methods on the general `menu_items` object.

## Migration

### From fixtures

#### Converter

You can convert your Rails fixtures to Oaken's seeds by running:

```
bin/rails generate oaken:convert:fixtures
```

This will convert anything in test/fixtures to db/seeds. E.g. `test/fixtures/users.yml` becomes `db/seeds/users.rb` and so on.

#### Disable fixtures

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

### From factories

If you've got a mostly working FactoryBot or Fabrication setup you may not want to muck with that too much.

However, you can grab some of the most shared records and shave off some significant runtime on your test suite.

<blockquote class="bluesky-embed" data-bluesky-uri="at://did:plc:ps3ygxhsn4khcrxeutdosdqk/app.bsky.feed.post/3lfb5zdb3p22z" data-bluesky-cid="bafyreiadxun7yqw4efafqzwzv3h4t4mbrex7onlnxobfejhbt6t44fojni" data-bluesky-embed-color-mode="system"><p lang="en">It&#x27;s @erikaxel.bsky.social&#x27;s team! They shaved 5.5 minutes off their test suite.

And that&#x27;s just the first batch integrating Oaken!<br><br><a href="https://bsky.app/profile/did:plc:ps3ygxhsn4khcrxeutdosdqk/post/3lfb5zdb3p22z?ref_src=embed">[image or embed]</a></p>&mdash; Kasper Timm Hansen (<a href="https://bsky.app/profile/did:plc:ps3ygxhsn4khcrxeutdosdqk?ref_src=embed">@kaspth.bsky.social</a>) <a href="https://bsky.app/profile/did:plc:ps3ygxhsn4khcrxeutdosdqk/post/3lfb5zdb3p22z?ref_src=embed">January 8, 2025 at 11:00 PM</a></blockquote>

Set Oaken up for your tests like the setup section mentions, and then only add a setup directory and scenarios around the root-level model like an Account. Like this:

```ruby
# db/seeds.rb
if Rails.env.test?
  Oaken.loader.seed :setup, :accounts
  return
end
```

Then define some very basic account setup like the very top of the README mentions.

Or maybe like this:

```ruby
# db/seeds/test/accounts/basic.rb
accounts.create :basic, **FactoryBot.attributes_for(:account)

# Maybe some extra necessary records on the account here.
```

Now tests can pass `account: accounts.basic` to other factories.

Do the very minimum and go slow. Pick records that you know are 100% safe to share.

> [!NOTE]
> I'd love to improve these migration notes. Please file an issue if something is confusing. I'd also love to hear your experience in general.

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

## Bug Report Template

When reporting bugs, please use our bug report template at [examples/bug_report_template.rb](examples/bug_report_template.rb)

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
