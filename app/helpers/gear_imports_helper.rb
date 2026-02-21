module GearImportsHelper
  def detect_field_name(header)
    header_lower = header.to_s.downcase
    
    return 'name' if header_lower.match?(/name|item/)
    return 'brand' if header_lower.match?(/brand|manufacturer|maker/)
    return 'model' if header_lower.match?(/model|version/)
    return 'weight' if header_lower.match?(/weight|mass|kg|kilogram/)
    return 'gear_category_id' if header_lower.match?(/category|type|class/)
    return 'notes' if header_lower.match?(/note|description|comment|detail/)
    
    'skip'
  end
end
