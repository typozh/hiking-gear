# frozen_string_literal: true

# GearItems Controller - handles gear inventory CRUD operations
class GearItemsController < ApplicationController
  before_action :set_gear_item, only: [:show, :edit, :update, :destroy]

  def index
    @gear_items = current_user.gear_items.includes(:gear_category)
    @gear_items = @gear_items.by_category(params[:category_id]) if params[:category_id].present?
    @gear_items = case params[:sort]
                  when 'heaviest'
                    @gear_items.heaviest_first
                  when 'lightest'
                    @gear_items.lightest_first
                  else
                    @gear_items.order(:name)
                  end
    @categories = GearCategory.all
  end

  def show
    @trips_using_gear = @gear_item.trips
  end

  def new
    @gear_item = current_user.gear_items.build
    @categories = GearCategory.all
  end

  def create
    @gear_item = current_user.gear_items.build(gear_item_params)

    if @gear_item.save
      flash[:notice] = 'Gear item created successfully'
      redirect_to @gear_item
    else
      @categories = GearCategory.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = GearCategory.all
  end

  def update
    if @gear_item.update(gear_item_params)
      flash[:notice] = 'Gear item updated successfully'
      redirect_to @gear_item
    else
      @categories = GearCategory.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @gear_item.destroy
    flash[:notice] = 'Gear item deleted successfully'
    redirect_to gear_items_path
  end

  private

  def set_gear_item
    @gear_item = current_user.gear_items.find(params[:id])
  end

  def gear_item_params
    params.require(:gear_item).permit(:name, :description, :weight, :quantity,
                                      :gear_category_id, :brand, :price, :consumable)
  end
end
