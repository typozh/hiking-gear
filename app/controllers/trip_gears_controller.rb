# frozen_string_literal: true

# TripGears Controller - handles adding/removing gear from trips
class TripGearsController < ApplicationController
  before_action :set_trip

  def create
    @trip_gear = @trip.trip_gears.build(trip_gear_params)

    if @trip_gear.save
      flash[:notice] = 'Gear added to trip'
      redirect_to @trip
    else
      flash[:alert] = 'Could not add gear to trip'
      redirect_to @trip
    end
  end

  def update
    @trip_gear = @trip.trip_gears.find(params[:id])

    if @trip_gear.update(trip_gear_params)
      flash[:notice] = 'Gear updated'
      redirect_to @trip
    else
      flash[:alert] = 'Could not update gear'
      redirect_to @trip
    end
  end

  def destroy
    @trip_gear = @trip.trip_gears.find(params[:id])
    @trip_gear.destroy
    flash[:notice] = 'Gear removed from trip'
    redirect_to @trip
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def trip_gear_params
    params.require(:trip_gear).permit(:gear_item_id, :quantity, :notes, :packed)
  end
end
