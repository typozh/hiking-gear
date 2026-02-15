# frozen_string_literal: true

# TripGear join model connecting trips and gear items
class TripGear < ApplicationRecord
  belongs_to :trip
  belongs_to :gear_item

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :gear_item_id, uniqueness: { scope: :trip_id }

  def total_weight
    gear_item.weight * quantity
  end
end
