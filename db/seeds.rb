%w[Food Transport Utilities Rent Shopping Entertainment Misc].each do |n|
  Category.find_or_create_by!(name: n)
end
