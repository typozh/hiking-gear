# frozen_string_literal: true

class GearImport < ApplicationRecord
  belongs_to :user
  has_many :gear_items, dependent: :nullify

  def revert!
    gear_items.destroy_all
    destroy
  end
end
