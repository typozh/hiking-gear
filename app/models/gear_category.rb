# frozen_string_literal: true

# GearCategory model for organizing gear by type
class GearCategory < ApplicationRecord
  has_many :gear_items, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def total_items_count
    gear_items.count
  end

  def average_weight
    gear_items.average(:weight) || 0
  end
end
