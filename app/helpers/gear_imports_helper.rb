module GearImportsHelper
  # Given a list of headers and a gear field key, return the best matching header name
  def detect_field_name_for(headers, field_key)
    headers.find { |h| column_matches_field?(h, field_key) } || 'skip'
  end

  private

  def column_matches_field?(header, field_key)
    h = header.to_s.downcase
    case field_key
    when 'name'            then h.match?(/name|item/)
    when 'brand'           then h.match?(/brand|manufacturer|maker/)
    when 'model'           then h.match?(/model|version/)
    when 'weight'          then h.match?(/weight|mass|kg|kilogram/)
    when 'gear_category_id' then h.match?(/category|type/)
    when 'notes'           then h.match?(/note|description|comment|detail/)
    else false
    end
  end
end
