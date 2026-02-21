# frozen_string_literal: true

require 'csv'

# GearItems Controller - handles gear inventory CRUD operations
class GearItemsController < ApplicationController
  before_action :set_gear_item, only: [:show, :edit, :update, :destroy]

  def index
    @gear_items = current_user.gear_items.includes(:gear_category)

    # Search
    @gear_items = @gear_items.search(params[:q])                                   if params[:q].present?
    # Filters
    @gear_items = @gear_items.by_category(params[:category_id])                    if params[:category_id].present?
    @gear_items = @gear_items.where(brand: params[:brand])                         if params[:brand].present?
    if params[:weight_min].present? || params[:weight_max].present?
      # UI values are in grams; DB stores kg
      min_kg = params[:weight_min].present? ? params[:weight_min].to_f / 1000.0 : 0
      max_kg = params[:weight_max].present? ? params[:weight_max].to_f / 1000.0 : Float::INFINITY
      @gear_items = @gear_items.weight_between(min_kg, max_kg)
    end
    @gear_items = @gear_items.unused                                                if params[:unused_only] == '1'

    # Sort
    @gear_items = case params[:sort]
                  when 'heaviest'  then @gear_items.heaviest_first
                  when 'lightest'  then @gear_items.lightest_first
                  when 'newest'    then @gear_items.by_date
                  when 'category'  then @gear_items.joins('LEFT JOIN gear_categories ON gear_categories.id = gear_items.gear_category_id').order('gear_categories.name ASC, gear_items.name ASC')
                  else                  @gear_items.order(:name)
                  end

    @categories  = GearCategory.all.order(:name)
    @brands      = current_user.gear_items.where.not(brand: [nil, '']).distinct.pluck(:brand).sort
    @view_mode   = params[:view].presence || cookies[:gear_view] || 'grid'
    cookies[:gear_view] = @view_mode
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

  def bulk_update
    ids        = params[:item_ids].presence || []
    category   = params[:bulk_category_id]
    items      = current_user.gear_items.where(id: ids)

    if category.present? && items.any?
      items.update_all(gear_category_id: category.presence)
      flash[:notice] = "Updated category for #{items.count} item(s)"
    else
      flash[:error] = 'Select at least one item and a target category'
    end
    redirect_to gear_items_path(request.query_parameters.except(:_method))
  end

  def bulk_destroy
    ids   = params[:item_ids].presence || []
    items = current_user.gear_items.where(id: ids)
    count = items.count
    items.destroy_all
    flash[:notice] = "Deleted #{count} item(s)"
    redirect_to gear_items_path(request.query_parameters.except(:_method))
  end

  def export
    @gear_items = current_user.gear_items.includes(:gear_category).order(:name)

    csv = CSV.generate(headers: true) do |csv|
      csv << ['Name', 'Brand', 'Category', 'Weight (kg)', 'Weight (g)', 'Quantity', 'Total Weight (g)', 'Price', 'Description']
      @gear_items.each do |item|
        csv << [
          item.name,
          item.brand,
          item.gear_category&.name,
          item.weight,
          item.weight_per_unit_grams,
          item.quantity,
          (item.total_weight * 1000).round,
          item.price,
          item.description
        ]
      end
    end

    send_data csv, filename: "gear-#{Date.today}.csv", type: 'text/csv'
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
