class GearImportsController < ApplicationController
  def new
    # Show upload form
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

      # Save the uploaded file to disk so we don't overflow the session cookie
      import_dir = Rails.root.join('tmp', 'imports')
      FileUtils.mkdir_p(import_dir)
      ext = File.extname(uploaded_file.original_filename)
      tmp_filename = "import_#{current_user.id}_#{Time.now.to_i}#{ext}"
      tmp_path = import_dir.join(tmp_filename).to_s
      FileUtils.cp(uploaded_file.tempfile.path, tmp_path)

      # Parse file to extract headers only
      spreadsheet = open_spreadsheet_path(tmp_path, ext)

      # Auto-detect the header row: find the row (within first 10) with the most non-empty cells
      last_scan_row = [spreadsheet.last_row, 10].min
      header_row_index = (1..last_scan_row).max_by { |i| spreadsheet.row(i).count { |c| c.present? } }
      headers = spreadsheet.row(header_row_index).map { |h| h&.to_s&.strip }.select(&:present?)

      # Store only the path, detected header row, and headers in the session (no bulk data in cookie)
      session[:import_tmp_path] = tmp_path
      session[:import_headers] = headers
      session[:import_header_row] = header_row_index
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
    @filename = session[:import_filename]
    tmp_path = session[:import_tmp_path]

    unless @headers && tmp_path && File.exist?(tmp_path)
      flash[:error] = "No file uploaded. Please upload a file first."
      redirect_to new_gear_import_path and return
    end

    @header_row = session[:import_header_row] || 1

    # Build preview rows by re-reading the file (avoids session cookie overflow)
    begin
      require 'roo'
      ext = File.extname(tmp_path)
      spreadsheet = open_spreadsheet_path(tmp_path, ext)
      # Show header row + up to 5 data rows
      start_row = @header_row
      end_row = [spreadsheet.last_row, start_row + 5].min
      @preview_rows = (start_row..end_row).map { |i| spreadsheet.row(i) }
    rescue => e
      @preview_rows = [@headers]
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

  def import_data
    # Process the import with user's column mapping
    mapping = params[:mapping] || {}
    tmp_path = session[:import_tmp_path]

    unless tmp_path && File.exist?(tmp_path)
      flash[:error] = "Import session expired. Please upload the file again."
      redirect_to new_gear_import_path and return
    end

    require 'roo'
    ext = File.extname(tmp_path)
    spreadsheet = open_spreadsheet_path(tmp_path, ext)
    header_row = (session[:import_header_row] || 1).to_i
    headers = spreadsheet.row(header_row).map { |h| h&.to_s&.strip }
    rows = ((header_row + 1)..spreadsheet.last_row).map { |i| spreadsheet.row(i) }

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
    
    # Clean up temp file and session data
    File.delete(tmp_path) rescue nil
    session.delete(:import_tmp_path)
    session.delete(:import_headers)
    session.delete(:import_header_row)
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

  def open_spreadsheet_path(path, extension)
    require 'roo'
    require 'roo-xls'

    case extension.downcase
    when '.csv'
      Roo::CSV.new(path)
    when '.xls'
      Roo::Excel.new(path)
    when '.xlsx'
      Roo::Excelx.new(path)
    else
      raise "Unknown file type: #{extension}"
    end
  end

  def find_category(value)
    # Try to find category by name first, then by ID
    GearCategory.find_by(name: value.to_s.strip) ||
      (GearCategory.find_by(id: value.to_i) if value.to_i.to_s == value.to_s.strip)
  end
end
