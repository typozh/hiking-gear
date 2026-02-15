# frozen_string_literal: true

# Seed data for hiking gear application

# Create gear categories
categories = [
  { name: 'Shelter', description: 'Tents, tarps, sleeping bags, sleeping pads', icon: '⛺' },
  { name: 'Cooking', description: 'Stoves, pots, utensils, fuel', icon: '🍳' },
  { name: 'Clothing', description: 'Layers, rain gear, insulation', icon: '👕' },
  { name: 'Navigation', description: 'Maps, compass, GPS devices', icon: '🧭' },
  { name: 'Hydration', description: 'Water bottles, filters, bladders', icon: '💧' },
  { name: 'Food', description: 'Meals, snacks, emergency food', icon: '🍕' },
  { name: 'First Aid', description: 'Medical supplies and safety gear', icon: '🏥' },
  { name: 'Tools', description: 'Knives, multi-tools, repair kits', icon: '🔧' },
  { name: 'Lighting', description: 'Headlamps, flashlights, lanterns', icon: '🔦' },
  { name: 'Hygiene', description: 'Toiletries and sanitation items', icon: '🧼' },
  { name: 'Electronics', description: 'Phone, camera, power banks', icon: '📱' },
  { name: 'Other', description: 'Miscellaneous gear', icon: '📦' }
]

puts 'Creating gear categories...'
categories.each do |cat|
  GearCategory.find_or_create_by!(name: cat[:name]) do |category|
    category.description = cat[:description]
    category.icon = cat[:icon]
  end
end
puts "Created #{GearCategory.count} categories"

# Create demo user (only in development)
if Rails.env.development?
  puts "\nCreating demo user..."
  demo_user = User.find_or_create_by!(email: 'demo@example.com') do |user|
    user.name = 'Demo User'
    user.password = 'password123'
    user.password_confirmation = 'password123'
  end
  puts "Demo user created: #{demo_user.email} / password123"

  # Add some sample gear for demo user
  puts "\nCreating sample gear items..."
  
  shelter = GearCategory.find_by(name: 'Shelter')
  cooking = GearCategory.find_by(name: 'Cooking')
  clothing = GearCategory.find_by(name: 'Clothing')
  hydration = GearCategory.find_by(name: 'Hydration')
  lighting = GearCategory.find_by(name: 'Lighting')

  sample_gear = [
    { name: 'Ultralight Tent', weight: 1.2, category: shelter, quantity: 1, brand: 'Big Agnes' },
    { name: 'Sleeping Bag (-10°C)', weight: 0.85, category: shelter, quantity: 1, brand: 'Western Mountaineering' },
    { name: 'Sleeping Pad', weight: 0.45, category: shelter, quantity: 1, brand: 'Therm-a-Rest' },
    { name: 'Backpack (60L)', weight: 1.1, category: nil, quantity: 1, brand: 'Osprey' },
    { name: 'Stove', weight: 0.095, category: cooking, quantity: 1, brand: 'MSR' },
    { name: 'Pot (1L)', weight: 0.12, category: cooking, quantity: 1, brand: 'TOAKS' },
    { name: 'Rain Jacket', weight: 0.25, category: clothing, quantity: 1, brand: 'Patagonia' },
    { name: 'Down Jacket', weight: 0.35, category: clothing, quantity: 1, brand: 'Montbell' },
    { name: 'Water Filter', weight: 0.085, category: hydration, quantity: 1, brand: 'Sawyer' },
    { name: 'Water Bottle (1L)', weight: 0.045, category: hydration, quantity: 2, brand: 'Smart Water' },
    { name: 'Headlamp', weight: 0.065, category: lighting, quantity: 1, brand: 'Petzl' }
  ]

  sample_gear.each do |gear|
    demo_user.gear_items.find_or_create_by!(name: gear[:name]) do |item|
      item.weight = gear[:weight]
      item.quantity = gear[:quantity]
      item.gear_category = gear[:category]
      item.brand = gear[:brand]
    end
  end

  puts "Created #{demo_user.gear_items.count} gear items"

  # Create a sample trip
  puts "\nCreating sample trip..."
  trip = demo_user.trips.find_or_create_by!(name: 'Weekend Mountain hike') do |t|
    t.description = 'Two-day backpacking trip in the mountains'
    t.start_date = Date.today + 14.days
    t.end_date = Date.today + 16.days
    t.location = 'Mountain Range National Park'
    t.target_weight_kg = 8.0
    t.difficulty_level = 'Moderate'
    t.status = 'planning'
  end

  # Add some gear to the trip
  essential_gear = demo_user.gear_items.where(name: ['Ultralight Tent', 'Sleeping Bag (-10°C)', 
                                                      'Sleeping Pad', 'Backpack (60L)', 'Stove',
                                                      'Pot (1L)', 'Water Filter', 'Headlamp'])
  essential_gear.each do |gear|
    trip.trip_gears.find_or_create_by!(gear_item: gear) do |tg|
      tg.quantity = 1
    end
  end

  puts "Created trip: #{trip.name}"
  puts "Total trip weight: #{trip.total_weight.round(2)} kg"

  puts "\n✅ Seed data created successfully!"
  puts "\nYou can login with:"
  puts "Email: demo@example.com"
  puts "Password: password123"
end
