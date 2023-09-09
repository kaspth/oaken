business = accounts.create :business, name: "Big Business Co."

users.create :kasper,   name: "Kasper",   accounts: [business]
users.create :coworker, name: "Coworker", accounts: [business]
