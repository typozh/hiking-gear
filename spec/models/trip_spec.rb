# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trip, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:trip_gears).dependent(:destroy) }
    it { is_expected.to have_many(:gear_items).through(:trip_gears) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:start_date) }
  end

  describe '#duration_days' do
    it 'calculates the duration in days' do
      trip = build(:trip, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 3))

      expect(trip.duration_days).to eq(3)
    end

    it 'returns 0 when dates are missing' do
      trip = build(:trip, start_date: nil, end_date: nil)

      expect(trip.duration_days).to eq(0)
    end
  end

  describe '#total_weight' do
    let(:user) { create(:user) }
    let(:trip) { create(:trip, user: user) }
    let(:gear1) { create(:gear_item, user: user, weight: 1.0) }
    let(:gear2) { create(:gear_item, user: user, weight: 0.5) }

    it 'calculates total weight of all gear in trip' do
      create(:trip_gear, trip: trip, gear_item: gear1, quantity: 1)
      create(:trip_gear, trip: trip, gear_item: gear2, quantity: 2)

      expect(trip.total_weight).to eq(2.0)
    end
  end

  describe '#weight_status' do
    let(:trip) { create(:trip, target_weight_kg: 10.0) }

    it 'returns "under" when below target weight' do
      allow(trip).to receive(:total_weight).and_return(8.0)

      expect(trip.weight_status).to eq('under')
    end

    it 'returns "close" when within 10% of target' do
      allow(trip).to receive(:total_weight).and_return(10.5)

      expect(trip.weight_status).to eq('close')
    end

    it 'returns "over" when significantly over target' do
      allow(trip).to receive(:total_weight).and_return(12.0)

      expect(trip.weight_status).to eq('over')
    end
  end
end
