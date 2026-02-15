# frozen_string_literal: true

# Trips Controller - handles trip CRUD operations
class TripsController < ApplicationController
  before_action :set_trip, only: [:show, :edit, :update, :destroy]

  def index
    @upcoming_trips = current_user.trips.upcoming
    @past_trips = current_user.trips.past
  end

  def show
    @trip_gears = @trip.trip_gears.includes(gear_item: :gear_category)
    @available_gear = current_user.gear_items.includes(:gear_category).where.not(id: @trip.gear_items.pluck(:id))
  end

  def new
    @trip = current_user.trips.build
  end

  def create
    @trip = current_user.trips.build(trip_params)

    if @trip.save
      flash[:notice] = 'Trip created successfully'
      redirect_to @trip
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      flash[:notice] = 'Trip updated successfully'
      redirect_to @trip
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    flash[:notice] = 'Trip deleted successfully'
    redirect_to trips_path
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:id])
  end

  def trip_params
    params.require(:trip).permit(:name, :description, :start_date, :end_date,
                                 :location, :target_weight_kg, :difficulty_level, :status)
  end
end
