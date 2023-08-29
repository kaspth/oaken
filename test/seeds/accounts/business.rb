business = accounts.update :business, name: "Big Business Co."

def accounts.increment_counter
  @counter ||= 0
  @counter += 1
end
accounts.increment_counter

users.update :kasper,   name: "Kasper",   accounts: [business]
users.update :coworker, name: "Coworker", accounts: [business]
