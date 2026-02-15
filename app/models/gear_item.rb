# frozen_string_literal: true

# GearItem model for individual pieces of hiking gear
class GearItem < ApplicationRecord
  belongs_to :user
  belongs_to :gear_category, optional: true
  has_many :trip_gears, dependent: :destroy
  has_many :trips, through: :trip_gears

  validates :name, presence: true
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }

  scope :by_category, ->(category_id) { where(gear_category_id: category_id) }
  scope :heaviest_first, -> { order(weight: :desc) }
  scope :lightest_first, -> { order(weight: :asc) }

  def total_weight
    weight * quantity
  end

  def used_in_trips_count
    trips.count
  end

  def weight_per_unit_grams
    (weight * 1000).round
  end
end
