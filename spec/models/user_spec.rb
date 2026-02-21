# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:trips).dependent(:destroy) }
    it { is_expected.to have_many(:gear_items).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to have_secure_password }
  end

  describe '#total_gear_weight' do
    let(:user) { create(:user) }

    it 'calculates total weight of all gear' do
      create(:gear_item, user: user, weight: 0.5, quantity: 2)
      create(:gear_item, user: user, weight: 1.0, quantity: 1)

      expect(user.total_gear_weight).to eq(2.0)
    end
  end

  describe '#total_gear_count' do
    let(:user) { create(:user) }

    it 'counts total number of gear items' do
      create_list(:gear_item, 3, user: user)

      expect(user.total_gear_count).to eq(3)
    end
  end
end
