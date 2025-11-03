# Seeds default categories for the Expense Tracker application
# Run with: bin/rails db:seed
%w[Food Transport Utilities Rent Shopping Entertainment Misc].each do |name|
  Category.find_or_create_by!(name: name)
end
