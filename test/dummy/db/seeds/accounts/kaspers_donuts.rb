section :accounts
donuts = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

section :users
kasper   = users.create :kasper,   name: "Kasper",   email_address: "kasper@example.com",   accounts: [donuts]
coworker = users.create :coworker, name: "Coworker", email_address: "coworker@example.com", accounts: [donuts]

section :menus, :with_items
menu = menus.create account: donuts
plain_donut     = menu_items.create menu: menu, name: "Plain",     price_cents: 10_00
sprinkled_donut = menu_items.create menu: menu, name: "Sprinkled", price_cents: 10_10
menus.label basic: menu

section :orders
supporter = users.create name: "Super Supporter"
orders.insert_all [user_id: supporter.id, item_id: plain_donut.id] * 10

orders.insert_all \
  10.times.map { { user_id: users.create.id, item_id: menu.items.sample.id } }
