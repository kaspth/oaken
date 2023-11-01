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
