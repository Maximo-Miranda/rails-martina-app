# frozen_string_literal: true

class CreateDefaultUsers < ActiveRecord::Migration[8.1]
  DEFAULT_USERS = [
    {
      email: "maximo.miranda@martinalawyer.co",
      full_name: "Maximo Miranda",
      role: "super_admin",
    },
    {
      email: "maximo.miranda@wudok.com",
      full_name: "Maximo Miranda",
      role: "admin",
    },
    {
      email: "maximomirandah@gmail.com",
      full_name: "Maximo Miranda",
      role: "blog_admin",
    },
  ].freeze

  def up
    DEFAULT_USERS.each do |user_data|
      user = User.find_or_create_by!(email: user_data[:email]) do |u|
        u.full_name = user_data[:full_name]
        u.password = "secret"
        u.password_confirmation = "secret"
      end

      user.update(confirmed_at: Time.current) unless user.confirmed_at
      user.add_role(user_data[:role]) unless user.has_role?(user_data[:role])
    end
  end

  def down
    DEFAULT_USERS.each do |user_data|
      user = User.find_by(email: user_data[:email])
      next unless user

      user.destroy
    end
  end
end
