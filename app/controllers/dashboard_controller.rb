# frozen_string_literal: true

# Dashboard Controller - home page and overview
class DashboardController < ApplicationController
  def index
    @upcoming_trips = current_user.trips.upcoming.limit(5)
    @total_gear_count = current_user.gear_items.count
    @total_gear_weight = current_user.total_gear_weight
    @recent_gear = current_user.gear_items.order(created_at: :desc).limit(5)
  end
end
