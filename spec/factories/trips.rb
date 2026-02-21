# frozen_string_literal: true

FactoryBot.define do
  factory :trip do
    association :user
    sequence(:name) { |n| "Trip #{n}" }
    description { 'A hiking adventure' }
    start_date { Date.today + 7.days }
    end_date { Date.today + 9.days }
    location { 'Mountain Range' }
    target_weight_kg { 10.0 }
    difficulty_level { 'Moderate' }
    status { 'planning' }
  end
end
