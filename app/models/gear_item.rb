# frozen_string_literal: true

# GearItem model for individual pieces of hiking gear
class GearItem < ApplicationRecord
  belongs_to :user
  belongs_to :gear_category, optional: true
  belongs_to :gear_import, optional: true
  has_many :trip_gears, dependent: :destroy
  has_many :trips, through: :trip_gears

  validates :name, presence: true
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }

  scope :by_category, ->(category_id) { where(gear_category_id: category_id) }
  scope :heaviest_first, -> { order(weight: :desc) }
  scope :lightest_first, -> { order(weight: :asc) }
  scope :by_date,        -> { order(created_at: :desc) }
  scope :unused,         -> { left_outer_joins(:trip_gears).where(trip_gears: { id: nil }) }
  scope :search,         ->(q) { where('LOWER(name) LIKE :q OR LOWER(brand) LIKE :q OR LOWER(description) LIKE :q', q: "%#{q.downcase}%") }
  scope :weight_between, ->(min, max) { where(weight: (min.to_f)..(max.to_f)) }

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
