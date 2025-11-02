loader.defaults name: -> { "Shouldn't be used for users.name" }, title: -> { "Global Default Title" }

grant_fixture_access accounts

section users do
  user_count, email_address_count = 0.step, 0.step
  users.defaults name: -> { "Customer #{user_count.next}" },
    email_address: -> { "email_address#{email_address_count.next}@example.com" }

  users.proxy :named_coworker
  users.proxy :admin, :mod, :plain

  def users.create(*, unique_by: :email_address, **o) = super
  def users.create_labeled(label, **o) = create(label, **o)
end

def plans.upsert(*, unique_by: :title, **o) = super
