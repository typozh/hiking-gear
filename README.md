# Hiking Gear Manager

A Ruby on Rails application for managing hiking gear across multiple trips with a focus on weight optimization and efficient gear planning.

## Features

- **Multi-user support** - Each user manages their own gear inventory
- **Trip planning** - Create and manage multiple hiking trips
- **Gear inventory** - Track all your hiking gear with weights and categories
- **Weight optimization** - Monitor total pack weight and optimize gear selection
- **Gear reusability** - Tag gear across multiple trips
- **Categories** - Organize gear by type (shelter, cooking, clothing, etc.)

## Models

### User
- Email, password (authentication)
- Has many trips
- Has many gear items

### Trip
- Name, description, start_date, end_date, duration
- Target weight, actual weight
- Belongs to user
- Has many gear items through trip_gears

### GearItem
- Name, description, weight, quantity, category
- Belongs to user
- Has many trips through trip_gears

### GearCategory
- Name, description
- Has many gear items

### TripGear (Join Table)
- Quantity for that specific trip
- Notes
- Belongs to trip and gear_item

## Getting Started

This is a Rails 7 application. To set up:

```bash
bundle install
rails db:create db:migrate db:seed
rails server
```

## Development

Run tests:
```bash
bundle exec rspec
```

Run linter:
```bash
bundle exec rubocop
```
