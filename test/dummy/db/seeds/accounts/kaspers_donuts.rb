donuts = accounts.create :kaspers_donuts, name: "Kasper's Donuts"

kasper = users.create :kasper, name: "Kasper"
administratorships.create account: donuts, user: kasper

register Menu::Item
menu = menus.create account: donuts
plain_donut = menu_items.create menu: menu, name: "Plain", price_cents: 10_00
sprinkled_donut = menu_items.create menu: menu, name: "Sprinkled", price_cents: 10_10

supporter = users.create name: "Super Supporter"
10.times do
  orders.create user: supporter, item: plain_donut
end

10.times do |n|
  customer = users.create name: "Customer #{n}"
  orders.create user: customer, item: menu.items.sample
end
