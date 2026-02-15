# frozen_string_literal: true

# User model for authentication and ownership
class User < ApplicationRecord
  has_secure_password

  has_many :trips, dependent: :destroy
  has_many :gear_items, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_digest_changed?

  def total_gear_weight
    gear_items.sum('weight * quantity')
  end

  def total_gear_count
    gear_items.count
  end
end
