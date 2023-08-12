accounts.update :business, name: "Big Business Co."

users.update :kasper, name: "Kasper", accounts: [accounts.business]
