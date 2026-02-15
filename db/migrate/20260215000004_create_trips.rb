# frozen_string_literal: true

# Migration to create trips table
class CreateTrips < ActiveRecord::Migration[7.1]
  def change
    create_table :trips do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.date :start_date, null: false
      t.date :end_date
      t.string :location
      t.decimal :target_weight_kg, precision: 10, scale: 3
      t.string :difficulty_level
      t.string :status, default: 'planning'

      t.timestamps
    end

    add_index :trips, [:user_id, :start_date]
  end
end
