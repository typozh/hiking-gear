# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GearItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:gear_category).optional }
    it { is_expected.to have_many(:trip_gears).dependent(:destroy) }
    it { is_expected.to have_many(:trips).through(:trip_gears) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:weight) }
    it { is_expected.to validate_numericality_of(:weight).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end

  describe '#total_weight' do
    it 'calculates weight times quantity' do
      gear = build(:gear_item, weight: 0.5, quantity: 3)

      expect(gear.total_weight).to eq(1.5)
    end
  end

  describe '#weight_per_unit_grams' do
    it 'converts weight to grams' do
      gear = build(:gear_item, weight: 0.25)

      expect(gear.weight_per_unit_grams).to eq(250)
    end
  end
end
