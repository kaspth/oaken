Oaken.prepare do
  register Menu::Item

  user_counter = 0
  users.defaults name: -> { "Customer #{user_counter += 1}" }

  seed :accounts, :data
end
