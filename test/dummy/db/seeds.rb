Oaken.prepare do
  section :registrations
  register Menu::Item

  section :roots
  user_counter = 0
  users.defaults name: -> { "Customer #{user_counter += 1}" }

  section :stems
  section :leafs

  section do
    seed :accounts, :data
  end
end
