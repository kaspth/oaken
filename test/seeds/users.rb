User = Struct.new(:name, keyword_init: true)
memory.register :users, User

users.update :kasper, name: "Kasper"
