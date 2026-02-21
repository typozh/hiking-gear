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
    # Intermediate step: validate mapping, then check for unknown categories
    mapping = params[:mapping] || {}
    tmp_path = session[:import_tmp_path]

    unless tmp_path && File.exist?(tmp_path)
      flash[:error] = "Import session expired. Please upload the file again."
      redirect_to new_gear_import_path and return
    end

    unless mapping['name'].present? && mapping['name'] != 'skip'
      flash[:error] = "Name field is required. Please map a column to the Name field."
      redirect_to map_gear_imports_path and return
    end

    # Save mapping in session for the next step
    session[:import_mapping] = mapping
    session.delete(:import_category_resolution)

    # If category column is mapped, scan data for unrecognised category values
    if mapping['gear_category_id'].present? && mapping['gear_category_id'] != 'skip'
      unknown = find_unknown_categories(mapping['gear_category_id'])
      if unknown.any?
        session[:import_unknown_categories] = unknown
        redirect_to resolve_categories_gear_imports_path and return
      end
    end

    # No unknown categories — import straight away
    perform_import
  end

  def resolve_categories
    @unknown_categories = session[:import_unknown_categories]
    @categories = GearCategory.all.order(:name)

    unless @unknown_categories&.any?
      flash[:error] = "Nothing to resolve. Please start over."
      redirect_to new_gear_import_path
    end
  end

  def do_import
    category_resolution = params[:category_resolution] || {}

    # Create any new categories the user requested
    category_resolution.each do |original_name, resolution|
      GearCategory.find_or_create_by(name: original_name) if resolution == 'create'
    end

    session[:import_category_resolution] = category_resolution
    perform_import
  end

  private

  def find_unknown_categories(column_name)
    tmp_path = session[:import_tmp_path]
    require 'roo'
    ext = File.extname(tmp_path)
    spreadsheet = open_spreadsheet_path(tmp_path, ext)
    header_row = (session[:import_header_row] || 1).to_i
    headers = spreadsheet.row(header_row).map { |h| h&.to_s&.strip }
    cat_col_index = headers.index(column_name)
    return [] unless cat_col_index

    cat_values = ((header_row + 1)..spreadsheet.last_row).map { |i|
      v = spreadsheet.row(i)[cat_col_index]
      v&.to_s&.strip
    }.select(&:present?).uniq

    existing_names = GearCategory.pluck(:name).map(&:downcase)
    cat_values.reject { |v| existing_names.include?(v.downcase) }
  end

  def perform_import
    mapping           = session[:import_mapping] || {}
    cat_resolution    = session[:import_category_resolution] || {}
    tmp_path          = session[:import_tmp_path]

    require 'roo'
    ext         = File.extname(tmp_path)
    spreadsheet = open_spreadsheet_path(tmp_path, ext)
    header_row  = (session[:import_header_row] || 1).to_i
    headers     = spreadsheet.row(header_row).map { |h| h&.to_s&.strip }
    rows        = ((header_row + 1)..spreadsheet.last_row).map { |i| spreadsheet.row(i) }

    column_to_field = {}
    mapping.each do |gear_field, column_name|
      next if column_name.blank? || column_name == 'skip'
      idx = headers.index(column_name)
      column_to_field[idx] = gear_field if idx
    end

    success_count    = 0
    errors           = []
    categories_cache = {}

    rows.each_with_index do |row, index|
      next if row.compact.empty?

      gear_params = { user_id: current_user.id }

      column_to_field.each do |col_index, field|
        value = row[col_index]
        next if value.blank?

        if field == 'gear_category_id'
          category = categories_cache[value.to_s] ||= resolve_category(value.to_s, cat_resolution)
          gear_params[:gear_category_id] = category&.id if category
        elsif field == 'weight'
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

    # Clean up temp file and all session keys
    File.delete(tmp_path) rescue nil
    %i[import_tmp_path import_headers import_header_row import_filename
       import_mapping import_unknown_categories import_category_resolution].each { |k| session.delete(k) }

    if success_count > 0
      flash[:success] = "Successfully imported #{success_count} gear item(s)"
      flash[:warning] = errors.join('<br>').html_safe if errors.any?
    else
      flash[:error] = "No items were imported. Errors: #{errors.join(', ')}"
    end

    redirect_to gear_items_path
  end

  def resolve_category(value, cat_resolution)
    resolution = cat_resolution[value]
    case resolution
    when 'skip', nil
      find_category(value)
    when 'create'
      GearCategory.find_by('LOWER(name) = LOWER(?)', value.strip)
    else
      GearCategory.find_by(id: resolution.to_i)
    end
  end

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
