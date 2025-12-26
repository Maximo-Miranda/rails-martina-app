# frozen_string_literal: true

class CreateDefaultRoles < ActiveRecord::Migration[8.1]
  GLOBAL_ROLES = %w[super_admin admin blog_admin blog_writer].freeze

  def up
    GLOBAL_ROLES.each { |role| Role.find_or_create_by!(name: role) }
  end

  def down
    Role.where(name: GLOBAL_ROLES, resource_type: nil).destroy_all
  end
end
