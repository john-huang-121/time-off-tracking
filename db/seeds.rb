# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Departments
departments = [ "Human Resources", "Marketing", "Engineering" ]

department_records = departments.index_with do |name|
  Department.find_or_create_by!(name: name)
end

default_password = "Password123!"

managers = [
  { email: "hr.manager1@example.com",  first_name: "Hannah", last_name: "Reed",  dept: "Human Resources", birth_date: Date.new(1988, 4, 12), phone: "714-555-0101" },
  { email: "mkt.manager1@example.com", first_name: "Marco",  last_name: "Klein", dept: "Marketing",      birth_date: Date.new(1986, 9, 3),  phone: "714-555-0102" },
  { email: "eng.manager1@example.com", first_name: "Evelyn", last_name: "Chen",  dept: "Engineering",    birth_date: Date.new(1990, 1, 27), phone: "714-555-0103" },
  { email: "eng.manager2@example.com", first_name: "Omar",   last_name: "Patel", dept: "Engineering",    birth_date: Date.new(1987, 6, 19), phone: "714-555-0104" }
]

managers.each do |m|
  user = User.find_or_initialize_by(email: m[:email])
  user.role = :manager
  if user.new_record?
    user.password = default_password
    user.password_confirmation = default_password
  end
  user.save!

  profile = user.profile || user.build_profile
  profile.first_name = m[:first_name]
  profile.last_name  = m[:last_name]
  profile.birth_date  = m[:birth_date]
  profile.phone_number = m[:phone]
  profile.department = department_records.fetch(m[:dept])
  profile.manager = nil
  profile.save!
end

puts "Seeded #{Department.count} departments"
puts "Seeded #{User.where(role: :manager).count} managers"
