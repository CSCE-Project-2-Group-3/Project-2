# Seeds default categories for the Expense Tracker application
# Run with: bin/rails db:seed
%w[Food Transport Utilities Rent Shopping Entertainment Misc].each do |name|
  Category.find_or_create_by!(name: name)
end

users_data = [
  { email: "alice@example.com", full_name: "Alice Johnson" },
  { email: "bob@example.com", full_name: "Bob Smith" },
  { email: "carol@example.com", full_name: "Carol Nguyen" },
  { email: "dave@example.com", full_name: "Dave Patel" }
]

seed_password = "password123"
users = users_data.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |user|
    user.full_name = attrs[:full_name]
    user.password = seed_password
  end
end

group = Group.find_or_create_by!(name: "Household Budget Crew")

users.each do |user|
  GroupMembership.find_or_create_by!(user: user, group: group)
end

categories = Category.where(name: %w[Food Transport Utilities Entertainment Misc]).index_by(&:name)
all_participant_ids = users.map(&:id)

expenses_data = [
  {
    title: "Grocery Run",
    amount: 120.50,
    spent_on: Date.current - 7,
    category: "Food",
    notes: "Weekly groceries at the supermarket",
    owner: users[0]
  },
  {
    title: "Ride Share",
    amount: 48.75,
    spent_on: Date.current - 5,
    category: "Transport",
    notes: "Shared rides to the office",
    owner: users[1]
  },
  {
    title: "Movie Night",
    amount: 64.00,
    spent_on: Date.current - 3,
    category: "Entertainment",
    notes: "Tickets and snacks",
    owner: users[2]
  },
  {
    title: "Utility Bill",
    amount: 95.30,
    spent_on: Date.current - 10,
    category: "Utilities",
    notes: "Electricity and water",
    owner: users[3]
  },
  {
    title: "Household Supplies",
    amount: 42.25,
    spent_on: Date.current - 1,
    category: "Misc",
    notes: "Cleaning and kitchen essentials",
    owner: users[0]
  }
]

expenses_data.each do |data|
  expense = Expense.find_or_initialize_by(
    title: data[:title],
    user: data[:owner],
    group: group,
    spent_on: data[:spent_on]
  )
  expense.category = categories.fetch(data[:category])
  expense.amount = data[:amount]
  expense.notes = data[:notes]
  expense.participant_ids = all_participant_ids
  expense.save!
end
