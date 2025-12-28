# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Crear roles globales (sin resource)
puts "Creating global roles..."
User::GLOBAL_ROLES.each do |role_name|
  Role.find_or_create_by!(name: role_name, resource_type: nil, resource_id: nil)
  puts "  - #{role_name}"
end

puts "Seeds completed!"
