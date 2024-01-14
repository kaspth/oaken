Oaken.prepare do
  section :registrations
  register Menu::Item

  section :roots
  user_counter = 0
  users.defaults name: -> { "Customer #{user_counter += 1}" }
  def users.create_labelled(label, **) = create(label, **)

  section :stems
  section :leafs
  def plans.upsert(*, unique_by: :title, **) = super

  section do
    seed :accounts, :data
  end
end
