Oaken.prepare do
  section :registrations
  register Menu::Item

  section :roots
  user_counter, email_address_counter = 0, 0
  users.defaults name: -> { "Customer #{user_counter += 1}" },
    email_address: -> { "email_address#{email_address_counter += 1}@example.com" }
  def users.create(*, unique_by: :email_address, **) = super
  def users.create_labelled(label, **) = create(label, **)

  section :stems
  section :leafs
  def plans.upsert(*, unique_by: :title, **) = super

  section do
    seed :accounts, :data
  end
end
