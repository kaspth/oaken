loader.defaults name: -> { "Shouldn't be used for users.name" }, title: -> { "Global Default Title" }

user_counter, email_address_counter = 0, 0
users.defaults name: -> { "Customer #{user_counter += 1}" },
  email_address: -> { "email_address#{email_address_counter += 1}@example.com" }
def users.create(*, unique_by: :email_address, **o) = super
def users.create_labeled(label, **o) = create(label, **o)

def plans.upsert(*, unique_by: :title, **o) = super
