# frozen_string_literal: true

# Migration to create gear_categories table
class CreateGearCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :gear_categories do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.string :icon

      t.timestamps
    end
  end
end
