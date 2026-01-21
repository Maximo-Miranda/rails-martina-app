# frozen_string_literal: true

class CreateCourtOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :court_orders do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :order_type, null: false
      t.text :summary
      t.date :order_date, null: false
      t.date :deadline
      t.string :status, default: "pendiente", null: false

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :court_orders, :deleted_at
    add_index :court_orders, :status
    add_index :court_orders, :deadline
    add_index :court_orders, %i[legal_case_id order_date]
  end
end
