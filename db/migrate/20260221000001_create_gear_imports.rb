# frozen_string_literal: true

class CreateGearImports < ActiveRecord::Migration[7.1]
  def change
    create_table :gear_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename
      t.integer :items_count, default: 0, null: false

      t.timestamps
    end
  end
end
