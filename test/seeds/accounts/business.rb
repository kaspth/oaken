business = accounts.update name: "Big Business Co."
accounts.access business: business

users.update name: "Kasper",   accounts: [business]
users.update name: "Coworker", accounts: [business]
users.access :kasper, :coworker
