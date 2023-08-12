accounts.update :business, name: "Big Business Co."

users.with accounts: [accounts.business]
users.update :kasper, name: "Kasper"
users.update :coworker, name: "Coworker"
