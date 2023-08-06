::User = Struct.new(:name, keyword_init: true)
memory.register User

users.update :kasper, name: "Kasper"
