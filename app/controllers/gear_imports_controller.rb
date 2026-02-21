class GearImportsController < ApplicationController
  def index
    @gear_imports = GearImport.where(user_id: current_user.id)
                              .order(created_at: :desc)
  end

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
    # Intermediate step: validate mapping, handle header row override, check for unknown categories
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

    # Allow user to override detected header row
    if params[:header_row].present?
      new_row = params[:header_row].to_i
      if new_row != session[:import_header_row].to_i && new_row >= 1
        require 'roo'
        ext = File.extname(tmp_path)
        spreadsheet = open_spreadsheet_path(tmp_path, ext)
        if new_row <= spreadsheet.last_row
          session[:import_header_row] = new_row
          session[:import_headers] = spreadsheet.row(new_row).map { |h| h&.to_s&.strip }.select(&:present?)
        end
      end
    end

    # Save mapping and weight unit in session for the next step
    session[:import_mapping] = mapping
    session[:import_weight_unit] = params[:weight_unit].presence || 'kg'
    session.delete(:import_category_resolution)

    # If category column is mapped, scan data for unrecognised category values
    if mapping['gear_category_id'].present? && mapping['gear_category_id'] != 'skip'
      unknown = find_unknown_categories(mapping['gear_category_id'])
      if unknown.any?
        session[:import_unknown_categories] = unknown
        redirect_to resolve_categories_gear_imports_path and return
      end
    end

    # No unknown categories — go to preview
    redirect_to preview_gear_imports_path
  end

  def revert
    @gear_import = GearImport.find_by(id: params[:id], user_id: current_user.id)
    unless @gear_import
      flash[:error] = "Import not found."
      redirect_to gear_imports_path and return
    end
    count = @gear_import.gear_items.count
    @gear_import.gear_items.destroy_all
    @gear_import.destroy
    flash[:success] = "Import reverted: #{count} gear item(s) deleted."
    redirect_to gear_imports_path
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
    redirect_to preview_gear_imports_path
  end

  def preview
    tmp_path = session[:import_tmp_path]
    unless tmp_path && File.exist?(tmp_path)
      flash[:error] = "Import session expired. Please upload the file again."
      redirect_to new_gear_import_path and return
    end

    mapping        = session[:import_mapping] || {}
    cat_resolution = session[:import_category_resolution] || {}
    weight_unit    = session[:import_weight_unit] || 'kg'

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

    existing_names = current_user.gear_items.pluck(:name).map(&:downcase).to_set
    categories_cache = {}

    @new_items       = []
    @duplicate_items = []
    @skipped_rows    = 0

    rows.each do |row|
      next if row.compact.empty? && (@skipped_rows += 1)

      item = {}
      column_to_field.each do |col_index, field|
        value = row[col_index]
        next if value.blank?
        if field == 'gear_category_id'
          cat = categories_cache[value.to_s] ||= resolve_category(value.to_s, cat_resolution)
          item['category'] = cat&.name
        elsif field == 'weight'
          item['weight'] = convert_weight(value.to_f, weight_unit)
        else
          item[field] = value.to_s.strip
        end
      end

      next if item['name'].blank?

      if existing_names.include?(item['name'].downcase)
        @duplicate_items << item
      else
        @new_items << item
      end
    end
  end

  def confirm_import
    session[:import_duplicate_action] = params[:duplicate_action].presence || 'skip'
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
    weight_unit       = session[:import_weight_unit] || 'kg'
    duplicate_action  = session[:import_duplicate_action] || 'skip'
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

    # Create an import record to allow revert later
    import_record = GearImport.create!(
      user_id:  current_user.id,
      filename: session[:import_filename] || 'unknown'
    )

    success_count    = 0
    errors           = []
    categories_cache = {}

    rows.each_with_index do |row, index|
      next if row.compact.empty?

      gear_params = { user_id: current_user.id, gear_import_id: import_record.id }

      column_to_field.each do |col_index, field|
        value = row[col_index]
        next if value.blank?

        if field == 'gear_category_id'
          category = categories_cache[value.to_s] ||= resolve_category(value.to_s, cat_resolution)
          gear_params[:gear_category_id] = category&.id if category
        elsif field == 'weight'
          gear_params[:weight] = convert_weight(value.to_f, weight_unit)
        else
          gear_params[field.to_sym] = value.to_s.strip
        end
      end

      gear_item = GearItem.find_by('LOWER(name) = LOWER(?) AND user_id = ?',
                                   gear_params[:name].to_s, current_user.id)

      if gear_item
        if duplicate_action == 'update'
          if gear_item.update(gear_params.except(:user_id, :gear_import_id))
            success_count += 1
          else
            errors << "Row #{index + 2}: #{gear_item.errors.full_messages.join(', ')}"
          end
        end
        # 'skip' (default) — do nothing
      else
        gear_item = GearItem.new(gear_params)
        if gear_item.save
          success_count += 1
        else
          errors << "Row #{index + 2}: #{gear_item.errors.full_messages.join(', ')}"
        end
      end
    end

    # Update the import record with the final count; remove it if nothing was imported
    if success_count > 0
      import_record.update!(items_count: success_count)
    else
      import_record.destroy
    end

    # Clean up temp file and all session keys
    File.delete(tmp_path) rescue nil
    %i[import_tmp_path import_headers import_header_row import_filename
       import_mapping import_weight_unit import_unknown_categories
       import_category_resolution import_duplicate_action].each { |k| session.delete(k) }

    if success_count > 0
      flash[:success] = "Successfully imported #{success_count} gear item(s)"
      flash[:warning] = errors.join('<br>').html_safe if errors.any?
    else
      flash[:error] = "No items were imported. Errors: #{errors.join(', ')}"
    end

    redirect_to gear_items_path
  end

  def convert_weight(value, unit)
    case unit
    when 'g'   then (value / 1000.0).round(3)
    when 'lbs' then (value * 0.453592).round(3)
    when 'oz'  then (value * 0.0283495).round(3)
    else value  # already kg
    end
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
