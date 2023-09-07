business = accounts.create name: "Big Business Co."
accounts.access business: business

users.create name: "Kasper",   accounts: [business]
users.create name: "Coworker", accounts: [business]
users.access :kasper, :coworker
