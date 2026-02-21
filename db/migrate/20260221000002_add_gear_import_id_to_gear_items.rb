# frozen_string_literal: true

class AddGearImportIdToGearItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :gear_items, :gear_import, null: true, foreign_key: true
  end
end
