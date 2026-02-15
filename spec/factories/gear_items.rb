# frozen_string_literal: true

FactoryBot.define do
  factory :gear_item do
    association :user
    association :gear_category
    sequence(:name) { |n| "Gear Item #{n}" }
    description { 'A piece of hiking gear' }
    weight { 0.5 }
    quantity { 1 }
    brand { 'Test Brand' }
    consumable { false }
  end
end
