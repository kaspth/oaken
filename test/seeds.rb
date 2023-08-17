accounts.with name: -> { id.to_s.humanize }
accounts.update :business, name: "Big Business Co."

users.with name: -> { id.to_s.capitalize }, accounts: [accounts.business]
users.update :kasper
users.update :coworker

comments.upsert :praise, title: "Nice!"
