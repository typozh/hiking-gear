# frozen_string_literal: true

# Migration to create trip_gears join table
class CreateTripGears < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_gears do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :gear_item, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.text :notes
      t.boolean :packed, default: false

      t.timestamps
    end

    add_index :trip_gears, [:trip_id, :gear_item_id], unique: true
  end
end
