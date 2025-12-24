class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :projects, :slug, unique: true
    add_index :projects, :deleted_at
  end
end
