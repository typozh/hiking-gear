class GearImportsController < ApplicationController
  before_action :require_login

  def new
    # Show upload form
    # Check if roo gem is available
    begin
      require 'roo'
      @roo_available = true
    rescue LoadError
      @roo_available = false
      flash.now[:warning] = "Import feature requires additional gems. Please run 'bundle install' on the server to enable file imports."
    end
  end

  def create
    # Handle file upload and parse headers
    uploaded_file = params[:file]
    
    unless uploaded_file
      flash[:error] = "Please select a file to upload"
      redirect_to new_gear_import_path and return
    end

    begin
      # Check if roo gem is available
      require 'roo'
      
      # Parse file to extract headers and preview data
      spreadsheet = open_spreadsheet(uploaded_file)
      headers = spreadsheet.row(1)
      
      # Store file data in session for mapping step
      session[:import_headers] = headers
      session[:import_data] = spreadsheet.to_a
      session[:import_filename] = uploaded_file.original_filename
      
      redirect_to map_gear_imports_path
    rescue LoadError
      flash[:error] = "Import feature requires additional gems. Please run 'bundle install' on the server."
      redirect_to new_gear_import_path
    rescue => e
      flash[:error] = "Error reading file: #{e.message}"
      redirect_to new_gear_import_path
    end
  end

  def map
    # Show column mapping form
    @headers = session[:import_headers]
    @preview_rows = session[:import_data]&.take(6) # Header + 5 preview rows
    @filename = session[:import_filename]
    
    unless @headers
      flash[:error] = "No file uploaded. Please upload a file first."
      redirect_to new_gear_import_path and return
    end
    
    # Get available gear fields for mapping
    @gear_fields = {
      'name' => 'Name (required)',
      'brand' => 'Brand',
      'model' => 'Model',
      'weight' => 'Weight (kg)',
      'notes' => 'Notes',
      'gear_category_id' => 'Category (use category name or ID)'
    }
    
    # Get all categories for reference
    @categories = GearCategory.all.order(:name)
  end

  def process
    # Process the import with user's column mapping
    mapping = params[:mapping] || {}
    import_data = session[:import_data]
    
    unless import_data
      flash[:error] = "Import session expired. Please upload the file again."
      redirect_to new_gear_import_path and return
    end
    
    headers = import_data[0]
    rows = import_data[1..-1] # Skip header row

    # Check if name field is mapped
    unless mapping['name'].present? && mapping['name'] != 'skip'
      flash[:error] = "Name field is required. Please map a column to the Name field."
      redirect_to map_gear_imports_path and return
    end

    # Build column_index => gear_field lookup
    # mapping is { gear_field => column_header_name }
    column_to_field = {}
    mapping.each do |gear_field, column_name|
      next if column_name.blank? || column_name == 'skip'
      column_index = headers.index(column_name)
      column_to_field[column_index] = gear_field if column_index
    end
    
    # Import gear items
    success_count = 0
    errors = []
    categories_cache = {}
    
    rows.each_with_index do |row, index|
      next if row.compact.empty? # Skip empty rows
      
      gear_params = { user_id: current_user.id }
      
      column_to_field.each do |col_index, field|
        value = row[col_index]
        next if value.blank?
        
        if field == 'gear_category_id'
          # Handle category mapping - try to find by name or ID
          category = categories_cache[value] ||= find_category(value)
          gear_params[:gear_category_id] = category&.id if category
        elsif field == 'weight'
          # Convert weight to float
          gear_params[:weight] = value.to_f
        else
          gear_params[field.to_sym] = value.to_s.strip
        end
      end
      
      gear_item = GearItem.new(gear_params)
      
      if gear_item.save
        success_count += 1
      else
        errors << "Row #{index + 2}: #{gear_item.errors.full_messages.join(', ')}"
      end
    end
    
    # Clear session data
    session.delete(:import_headers)
    session.delete(:import_data)
    session.delete(:import_filename)
    
    if success_count > 0
      flash[:success] = "Successfully imported #{success_count} gear item(s)"
      flash[:warning] = errors.join("<br>").html_safe if errors.any?
    else
      flash[:error] = "No items were imported. Errors: #{errors.join(', ')}"
    end
    
    redirect_to gear_items_path
  end

  private

  def open_spreadsheet(file)
    require 'roo'
    require 'roo-xls'
    
    extension = File.extname(file.original_filename)
    
    case extension
    when '.csv'
      klass = Object.const_get('Roo::CSV')
      klass.new(file.path)
    when '.xls'
      klass = Object.const_get('Roo::Excel')
      klass.new(file.path)
    when '.xlsx'
      klass = Object.const_get('Roo::Excelx')
      klass.new(file.path)
    else
      raise "Unknown file type: #{file.original_filename}"
    end
  end

  def find_category(value)
    # Try to find category by name first, then by ID
    GearCategory.find_by(name: value.to_s.strip) || 
    GearCategory.find_by(id: value.to_i) if value.to_i.to_s == value.to_s
  end

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to import gear"
      redirect_to login_path
    end
  end
end
