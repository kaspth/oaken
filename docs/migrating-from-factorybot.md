# [WIP] Migrating from FactoryBot

Thoughts/ideas on how to introduce Oaken into your codebase, either alongside or to ultimately replace FactoryBot.

## Outline

1. Get a handle on your object graph
   - Identify root-level models
     - Oaken is designed to mirror how your app works
   - Identify pure "seed"/"reference data" (shared records)
     - These could be candidates for seeding at the beginning of your test suite (if not already)
   - Identify models with zero/one associations
     - These could be the first refactors

2. Start using Oaken in development
   - Idea 1: Upgrade existing development seeds with Oaken
     - Rationale:
       - Oaken is worth using just for the seeding features in development
         - Personal anecdote: I got many of the benefits of the Seed-Fu gem
       - Probably already have seeds that you can streamline/optimize
         - Personal anecdote: I replaced a complicated seeding task with Oaken 
       - You can stop here and still be better off than before you started with Oaken
         - No one says you have to use Oaken for tests, but this could be the gateway drug

3. Testing - Use Oaken alongside FactoryBot
   - Configure Oaken with your test suite
     - Add `require "oaken/rspec_setup"` to `rails_helper.rb`

   - Idea 1: Seed shared records at the beginning of the test run
     - Rationale:
       - Simplify test setup
       - Consolidate dev/test data
     - Suggested approach:
       - Configure `seeds.rb` with handling for test environment
       - If that breaks tests:
         - Check for redundant setup actions
         - Are there let!/before blocks that you can remove?

   - Idea 2: Bridge the gap - Start using Oaken's factory-like features with existing specs
     - Rationale:
       - Specs may only require trivial changes
       - Simple factories translate well to Oaken defaults
       - Simple traits translate well to Oaken helpers
     - Suggested approach:
       - Create new defaults/helper methods 
       - Use in the same way/places as factories (inside let/before blocks)
         - build -> `s/build(:thing, ...)/things.build(...)/`
         - create -> `s/create(:thing, ...)/things.create(...)/`

   - Idea 3: Start using Oaken for new features
     - Rationale:
       - YMMV, but a new feature may be a good opportunity to start using Oaken
       - This is trivial if the new feature is introducing a new root model
       - This is still reasonable if your feature is only loosely coupled with the existing models/factories
     - Suggested approach:
       - Create Oaken fixtures (try out the features)
         - Try out labels?
         - Maybe you need to organize into cases?
       - Create new defaults/helper methods
       - Update seeds.rb

4. The last 10%
   - **WIP**
   - Not 100% sure what this should contain
     - In my own codebases I'm starting to re-think how I test certain things.
     - Maybe this could contain a "cookbook" of sorts, with recipes for refactoring Rspec/FactoryBot paradigms that don't quite translate to Oaken?

## Get a handle on your object graph

Oaken helps you build an object graph that reflects your domain model. So for best results, spend some time upfront getting (re)acquainted with your app's models and how they relate to each other.

Granted, that's usually easier said than done... so, where does one start?

### Categorizing models

It can be helpful to break down the object graph by grouping models into categories:

- Primary: a root-level model like Account and it's Users with 1-4 other models, the most basic crucial data to have to bootstrap the app.
- Secondary: models that hang off the primary ones, like Sessions for a User, Invites for an Account
- Tertiary: everything else that may hang off of primary + secondary models, probably a good case for factories

The lines between these categories can be pretty blurry, so treat this like a framing device rather than a rule.

### Tip: Explore the object graph using the Rails console

Here's a way to identify models with few associations using the Rails console

```
# Enable eager loading
dummy(dev)> Rails.application.eager_load!
=> nil

# Get number of total models
dummy(dev)> ApplicationRecord.descendants.size
=> 8

# List all models
dummy(dev)> ApplicationRecord.descendants
=>
[Menu::Item::Detail (call 'Menu::Item::Detail.load_schema' to load schema informations),
 Menu::Item (call 'Menu::Item.load_schema' to load schema informations),
 User (call 'User.load_schema' to load schema informations),
 Plan (call 'Plan.load_schema' to load schema informations),
 Order (call 'Order.load_schema' to load schema informations),
 Menu (call 'Menu.load_schema' to load schema informations),
 Administratorship (call 'Administratorship.load_schema' to load schema informations),
 Account (call 'Account.load_schema' to load schema informations)]

# List models with a single association
dummy(dev)> ApplicationRecord.descendants.select { _1.reflect_on_all_associations.size < 2 }
=> 
[Menu::Item::Detail (call 'Menu::Item::Detail.load_schema' to load schema informations),
 Menu::Item (call 'Menu::Item.load_schema' to load schema informations),
 Plan (call 'Plan.load_schema' to load schema informations)]
```

## (WIP) Gotchas and things that work differently

> FYI - These are "gotchas" from my personal experience. I'm not 100% sure how to organize these.

Oaken's factory-esque features can frequently be a drop-in replacement for FactoryBot, but nevertheless, there are some differences that FactoryBot users should be aware of.

### Sequences

FactoryBot sequences can generally be replaced with Ruby's `Numeric#step` captured in local variables that you pass to blocks in `defaults`. Like this:

```ruby
# db/seeds/setup.rb
user_count, email_address_count = 0.step, 0.step
users.defaults name: -> { "Customer #{user_count.next}" },
  email_address: -> { "email_address#{email_address_count.next}@example.com" }

# Or set them globally on the loader if it's safe to do so:
loader.defaults name: -> { "Customer #{user_count.next}" },
  email_address: -> { "email_address#{email_address_count.next}@example.com" }
```

### Build Strategies

While FactoryBot offers build strategies as a feature, Oaken is more explicit by design, requiring the developer to choose between build and create upfront. This can seem frustrating when attempting to replicate factories that one would typically use with build AND/OR create AND/OR build_stubbed. 

**build_stubbed**

Thinking out loud - Is there a comparable approach for build_stubbed with Oaken?

- I'm thinking that there isn't (and that there probably shouldn't be) because stubbing isn't what Oaken is all about
- And... perhaps that's a good thing?

> **Personal anecdote:** When migrating some factories/specs i found a couple of cases where `build_stubbed` didn't behave as i expected, and my specs weren't testing what I thought they were...

### Associations

Build strategies become more important with associated models.

**FactoryBot**

One generally just declares the association:

```ruby
# user_factory.rb
factory :user do
  account  # declared once in factory
end
```

The build strategy is specified by the calling code (eg, the spec) and cascades through all associated factories/models automatically.

```ruby
# Usage - account auto-created/built based on strategy
create(:user)         # creates user AND account
build(:user)          # builds user AND account (both non-persisted)
build_stubbed(:user)  # stubs both
```

**Oaken**

Associations are always explicit. So if a spec relies on both build(:user) and create(:user), you can:

**WIP** I think this would benefit from some less trivial examples...

1. Accept explicitness in tests

```ruby
# spec
it "tests non-persisted records" do
  account = accounts.build
  user = users.build(accounts: [account])

  # expect(user).to eq(...)
end

it "tests persisted records" do
  account = accounts.create
  user = users.create(accounts: [account])

  # expect(user).to eq(...)
end

```

2. Create separate helpers

```ruby
# db/seeds/setup.rb
def users.build_with_account(label = nil, accounts: [accounts.build], **)
  build(label, accounts:, **)
end

def users.create_with_account(label = nil, accounts: [accounts.create], **)
  create(label, accounts:, **)
end

# spec
it "tests non-persisted records" do
  user = users.build_with_account

  # expect(user).to eq(...)
end

it "tests persisted records" do
  user = users.create_with_account

  # expect(user).to eq(...)
end
```

3. Rethink the spec
   - Does the spec actually need a non-persisted record?
     - Is build used out of habit rather than necessity?
   - Is this worth refactoring to use seeded records?
     - Reference a pre-seeded user/account instead of building one per-test?

4. Keep the factory?
   - Oaken and FactoryBot can coexist...

**The tradeoff:**

- FactoryBot: More flexibility, but associations can cascade unexpectedly (one factory pulls in the whole app)
- Oaken: More code, but more explicit. You always know what's being built/created
