# frozen_string_literal: true

# TripGears Controller - handles adding/removing gear from trips
class TripGearsController < ApplicationController
  before_action :set_trip

  def create
    @trip_gear = @trip.trip_gears.build(trip_gear_params)

    respond_to do |format|
      if @trip_gear.save
        format.html do
          flash[:notice] = 'Gear added to trip'
          redirect_to @trip
        end
        format.json { render json: { success: true, trip_gear: @trip_gear }, status: :created }
      else
        format.html do
          flash[:alert] = 'Could not add gear to trip'
          redirect_to @trip
        end
        format.json { render json: { error: @trip_gear.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @trip_gear = @trip.trip_gears.find(params[:id])

    respond_to do |format|
      if @trip_gear.update(trip_gear_params)
        format.html do
          flash[:notice] = 'Gear updated'
          redirect_to @trip
        end
        format.json { render json: { success: true, trip_gear: @trip_gear }, status: :ok }
      else
        format.html do
          flash[:alert] = 'Could not update gear'
          redirect_to @trip
        end
        format.json { render json: { error: @trip_gear.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @trip_gear = @trip.trip_gears.find(params[:id])
    
    respond_to do |format|
      if @trip_gear.destroy
        format.html do
          flash[:notice] = 'Gear removed from trip'
          redirect_to @trip
        end
        format.json { render json: { success: true }, status: :ok }
      else
        format.html do
          flash[:alert] = 'Could not remove gear'
          redirect_to @trip
        end
        format.json { render json: { error: 'Failed to remove gear' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def trip_gear_params
    params.require(:trip_gear).permit(:gear_item_id, :quantity, :notes, :packed)
  end
end
