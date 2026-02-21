# frozen_string_literal: true

# Trip model for hiking trip planning
class Trip < ApplicationRecord
  belongs_to :user
  has_many :trip_gears, dependent: :destroy
  has_many :gear_items, through: :trip_gears

  validates :name, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date

  scope :upcoming, -> { where('start_date >= ?', Date.today).order(:start_date) }
  scope :past, -> { where('start_date < ?', Date.today).order(start_date: :desc) }

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  def total_weight
    trip_gears.joins(:gear_item).sum('gear_items.weight * trip_gears.quantity')
  end

  def total_items_count
    trip_gears.sum(:quantity)
  end

  def weight_status
    return 'unknown' unless target_weight_kg

    actual = total_weight
    if actual <= target_weight_kg
      'under'
    elsif actual <= target_weight_kg * 1.1
      'close'
    else
      'over'
    end
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end
