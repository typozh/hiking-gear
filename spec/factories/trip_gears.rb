# frozen_string_literal: true

FactoryBot.define do
  factory :trip_gear do
    association :trip
    association :gear_item
    quantity { 1 }
    packed { false }
  end
end
