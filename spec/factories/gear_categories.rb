# frozen_string_literal: true

FactoryBot.define do
  factory :gear_category do
    sequence(:name) { |n| "Category #{n}" }
    description { 'A gear category for hiking equipment' }
    icon { '📦' }
  end
end
