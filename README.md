# Oaken

Oaken brings conventions to your Rails app's test data and development seeds using structured seed scripts that you write in Ruby.

- Dramatically faster tests than factories
  - One team saw **3x faster test runs**
  - Another cut **5 min off their 20 min CI** in a day's work, and that was scratching the surface

- Replace super slow "pull in the world" factories with structured seed scripts loaded once before tests run
- Retains factory-like ergonomics in a new simpler approach

- Fully **replace Rails' fixtures** while staying near the same speed and skip complex YAML spread over many files

- Not an either-or: you can still use factories and fixtures with Oaken

- Faster onboarding: you can **reuse your test data as development seeds** which helps new developers understand your app faster
- Lower maintenance costs: you'll have less code and more visibility into your app's object graph
- Code as documentation: your seed scripts help reveal your app and functions like runnable documentation

---

> Thanks for this wonderful project! My head doesn't grok factories and I just want vanilla Rails testing with something better than fixtures, and this is so much better.
>
> The default YAML fixtures is somehow both too simple and too convoluted. It's hard to reference complex associations with it, and the fact that the data gets spread across many files makes it hard to read and harder to grasp.
>
> Oaken, on the other hand, is closer to using the console, which we already know, only in a repeatable and tidier way. The testing data/seeds setup process just feels more intentional this way.
>
> [@evenreven](https://github.com/evenreven)

> But seriously; Oaken is one of the single greatest tools I've added to my belt in the past year
>
> It's made cross-environment shared data, data prepping for demos, edge-case tests, and overall development much more reliable & shareable across a team
>
> [@tcannonfodder](https://github.com/tcannonfodder)

## Setup

See the [examples](examples) directory for a quick start.

Oaken is organized around structured seed scripts written in Ruby placed in `db/seeds/` that you load once ahead of time in tests. You can optionally reuse the same test data for your development seeds.

Tests are wrapped in transactions that are rolled back after the test finishes, just like Rails' fixtures. So you're free to create, update, and destroy within tests. If this is your first time working with transactional tests there are a few gotchas, like asserting on the delta to keep in mind. See here.

For Rails tests, put this in your `test/test_helper.rb`:

```ruby
class ActiveSupport::TestCase
  parallelize workers: :number_of_processors

  include Oaken.test_setup
end
```

> [!INFO]
> Rails' parallel tests are supported out of the box.

For RSpec specs, put this in `spec/rails_helper.rb`:

```ruby
require "oaken/rspec_setup"
```

Next let's look at what a seed file looks like and then how to load them.

### Writing and loading a simple seed file

Oaken seed files are Ruby files in `db/seeds/`. They're meant to follow the same steps in the same order a user would when interacting with your app, so feel free to get into a bit of storytelling.

For instance, let's say we're working on a Donut Shop management app that lets admins set up menu items in a backoffice. Our seed file could look like this:

```ruby
# db/seeds/test/accounts/kaspers_donuts.rb
account = Account.create! name: "Kasper's Donuts"

User.admin.create! name: "Kasper", email_address: "kasper@example.com", accounts: [account]
# We can blend in factories too!
FactoryBot.create :user, :admin, name: "Coworker", email_address: "coworker@example.com", accounts: [account] 

menu = Menu.create!(account:)
plain_donut     = Menu::Item.create! menu:, name: "Plain",     price_cents: 10_00
sprinkled_donut = Menu::Item.create! menu:, name: "Sprinkled", price_cents: 10_10
```

Since seed files are Ruby scripts we can use standard Active Record and we can even blend in our factories. We also get to show a similar path as a user would take.

In a real app, it would help show an onboarding developer clues about what comes first in the app and help them form the proper mental model quicker. Developers using Oaken have also mentioned that seeing their object graph written out sequentially has helped them spot potential issues with their domain model. They can now then fix them before they reach production and become harder to change & more costly to do so.

Next, we head to `db/seeds.rb` and tell Oaken to load it before tests run by calling `Oaken.seed`:

```ruby
Oaken.seed :accounts
```

This makes Oaken use a `accounts/{,**/*}.rb` file glob in `db/seeds/` and `db/seeds/test/` which matches on `db/seeds/test/accounts/kaspers_donuts.rb` and loads it. We'll cover loading more in depth later.

Finally, we can now refer to these pre-seeded objects in tests:

```ruby
setup { @user = User.find_by! name: "Kasper" } # Rails tests
let(:user) { User.find_by! name: "Kasper" } # RSpec
```

But this already gets clunky, so let's look at Oaken's answer to this.

#### Using Oaken's structured seed scripts

Writing seed scripts in plain Active Record has a number of drawbacks:

- Code grows inconsistent over time
- There's no conventional place for seed-specific code, like helpers
- There's no way to set common defaults for new columns
- Referring to seeded data in tests is clunky

Instead, Oaken has [Oaken::Stored::ActiveRecord](blob/main/lib/oaken/stored/active_record.rb) to wrap Active Records and solve the issues above.

You can manually register records to be wrapped like this:

```ruby
register Account, as: :accounts
register User, as: :users
register Menu, as: :menus
register Menu::Item, as: :menu_items
```

However, Oaken will do this for you automatically and you don't have to.

Now we can write our script like this:

```ruby
# db/seeds/test/accounts/kaspers_donuts.rb
account = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper   = users.admin.create :kasper,   name: "Kasper",   email_address: "kasper@example.com",   accounts: [account]
coworker = users.admin.create :coworker, name: "Coworker", email_address: "coworker@example.com", accounts: [account]

menu = menus.create(account:)
plain_donut     = menu_items.create menu:, name: "Plain",     price_cents: 10_00
sprinkled_donut = menu_items.create menu:, name: "Sprinkled", price_cents: 10_10
```

You can then refer to `accounts.kaspers_donuts` and `users.kasper` in tests. Similar to fixtures, Oaken doesn't cache these and each call returns a new instance.

---

Here Oaken also solves a major data consistency issue with RSpec's `let` caching that often leads to subtle bugs.

Consider a request test that intends to update a user name:

```ruby
let(:user) { create(:user) }

it "achieves metamorphosis" do
  put user_url(user), params: { name: "Gregor Samsa" }

  expect(user.name).to be_equal("Gregor Samsa")
end
```

If the request

If you meant to mutate a record in a request, you have to remember to call `reload` on the record 

or subtle data bugs can creep in. If you instead refer to `users.kasper` without using `let` it'll work!

```ruby
it "achieves metamorphosis" do
  put user_url(users.kasper), params: { name: "Gregor Samsa" }

  expect(users.kasper.name).to be_equal("Gregor Samsa")
end
```

### Loading seeds via db/seeds.rb

You can place them in a few different places:

- `db/seeds/test/` for test-only seeds
- `db/seeds/development/` for development-only seeds
- `db/seeds/` for cross-environment seeds that are loaded in test and development.

Oaken also supports per-environment seeds in `db/seeds/<Rails.env>/`. So you can put test only seeds in `db/seeds/test/` and development only seeds in `db/seeds/development/`, while putting cross-environment seeds directly in `db/seeds/`.

This happens by calling `Oaken.seed` in `db/seeds.rb`, like this:

```ruby
Oaken.seed :data
```

This tells `Oaken.seed` to look for seed scripts in `db/seeds/` via a `data` file glob `data{,/**/*}.rb`. This gives you control and flexibility over how to structure your data.

First, files are matched with the glob `data{,/**/*}.rb`


> [!NOTE]
> Internally, `Oaken.seed` uses `Oaken.lookup_paths` same as how `Kernel#require` uses `$LOAD_PATH`.

> [!TIP]
> Call `Oaken.glob(:data)` in a console and we'll return the files we'll match.

> [!NOTE]
> Choosing whether a particular seed is loaded in test and/or development is about where you place it.

> [!TIP]
> You could also have a cases directory that you load on demand in a console like `Oaken.seed "performance/small"`.

> [!TIP]
> Having development seed data be both what you see in your dev browser and your tests helps strengthen your understanding of your app's domain model. It'll make for easier onboarding of new developers and it's less work than maintaining two datasets.

## Next Steps

### Understanding loaders

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

Any directories and/or single-file matches are loaded in the order they're specified. So `loader.seed :data, :accounts` would first load data and then accounts.

> [!IMPORTANT]
> Understanding and making effective use of Oaken's directory loading will pay dividends for your usage. You generally want to have 1 top-level directive `seed` call to dictate how seeding happens in e.g. `db/seeds.rb` and then let individual seed files load in no specified order within that.

#### Using the `setup` phase

When you call `Oaken.seed`/`Oaken.loader.seed` we'll also call `seed :setup` for you behind the scenes, though we'll only call this once. It's meant for common setup, like setting `defaults` and defining helpers.

> [!IMPORTANT]
> Don't use `create`/`upsert` directly in setup. Add the `defaults` and/or helpers that would be useful in the later seed files.

Here's some files you could add:

- `db/seeds/setup.rb` — particularly useful as a starting point.
- `db/seeds/setup/defaults.rb` — loader and type-specific defaults.
- `db/seeds/setup/defaults/*.rb` — you could split out more specific files.
- `db/seeds/setup/users.rb` — a type specific file for its defaults/helpers, doesn't have to just be users.

- `db/seeds/development/setup.rb` — some defaults/helpers we only want in development.
- `db/seeds/test/setup.rb` — some defaults/helpers we only want in test.

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
Oaken.loader.seed :data, :accounts
Oaken.seed :data, :accounts # Or just this for short.
```

Both `bin/rails db:seed` and `bin/rails db:seed:replant` work as usual.

#### In the console

If you're in the `bin/rails console`, you can invoke the same `seed` method as in `db/seeds.rb`.

```ruby
Oaken.seed "cases/pagination"
```

This is useful if you're working on hammering out a single seed script.

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

#### `new`/`build`

We've also got `new`/`build` in case you:

- have a record that needs slightly more complex setup so you can't do `create`/`upsert`.
- want a record that's not in the database during testing.

Will have defaults applied via `attributes_for` internally.

```ruby
test "some test" do
  user = users.new name: "Someone"
  user = users.build name: "Someone"
end
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
# Set up a helper to ensure when we create an account we also have a default admin user.
def accounts.bootstrap(name:, **)
  create(name:, **).tap do
    context.users.admin.create account: _1, name: "Primary Admin"
  end
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
  Oaken.seed :accounts
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
