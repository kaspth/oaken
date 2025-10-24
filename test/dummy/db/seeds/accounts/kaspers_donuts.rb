section :account # This is our default account setup that's used for authenticating in integration/system tests.
account = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper   = users.admin.create :kasper, name: "Kasper",   email_address: "kasper@example.com",   accounts: [account]
coworker = users.mod.create :coworker, name: "Coworker", email_address: "coworker@example.com", accounts: [account]

users.with name: "With User", email_address: "with-user@example.com" do
  _1.create_labeled :created_from_with
end

administratorships.label kasper_administratorship: kasper.administratorships.first

menu = menus.create(account:)
plain_donut     = menu_items.create menu:, name: "Plain",     price_cents: 10_00
sprinkled_donut = menu_items.create menu:, name: "Sprinkled", price_cents: 10_10
menus.label basic: menu

menu_item_details.create :plain, menu_item: plain_donut, description: "Plain, but mighty."

supporter = users.create name: "Super Supporter"
orders.insert_all [user_id: supporter.id, item_id: plain_donut.id] * 10

orders.insert_all \
  10.times.map { { user_id: users.create.id, item_id: menu.items.sample.id } }
