# frozen_string_literal: true

# Migration to create gear_items table
class CreateGearItems < ActiveRecord::Migration[7.1]
  def change
    create_table :gear_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :gear_category, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :weight, precision: 10, scale: 3, null: false, comment: 'Weight in kg'
      t.integer :quantity, default: 1, null: false
      t.string :brand
      t.decimal :price, precision: 10, scale: 2
      t.boolean :consumable, default: false

      t.timestamps
    end

    add_index :gear_items, [:user_id, :name]
  end
end
