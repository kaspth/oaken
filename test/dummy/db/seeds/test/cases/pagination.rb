item_id = accounts.kaspers_donuts.menus.first.items.pick(:id)

orders.insert_all [user_id: users.kasper.id, item_id:] * 100
