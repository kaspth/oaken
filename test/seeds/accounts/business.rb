business = accounts.update :business, name: "Big Business Co."

users.update :kasper,   name: "Kasper",   accounts: [business]
users.update :coworker, name: "Coworker", accounts: [business]
