# Hiking Gear Manager - Setup Instructions

## Quick Start

This is a complete Ruby on Rails application for managing hiking gear and trip planning. Follow these steps to get it running.

### Prerequisites

- Ruby 3.3.0+ (use rbenv or rvm)
- Rails 7.1+
- SQLite3 (or PostgreSQL if you prefer)
- Node.js 20+ (for asset compilation)

### Installation Steps

1. **Navigate to the application directory:**
   ```bash
   cd hiking_gear_app
   ```

2. **Install gem dependencies:**
   ```bash
   bundle install
   ```

3. **Install JavaScript dependencies (if using importmap):**
   ```bash
   rails importmap:install
   rails turbo:install
   rails stimulus:install
   ```

4. **Set up the database:**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

5. **Start the Rails server:**
   ```bash
   rails server
   ```

6. **Visit the application:**
   Open your browser and go to `http://localhost:3000`

7. **Login with demo account:**
   - Email: `demo@example.com`
   - Password: `password123`

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage (if you add simplecov)
COVERAGE=true bundle exec rspec
```

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Database Commands

```bash
# Reset database (caution: deletes all data)
rails db:reset

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status
```

## Application Structure

```
hiking_gear_app/
├── app/
│   ├── controllers/        # Request handlers
│   ├── models/             # Data models (User, Trip, GearItem, etc.)
│   ├── views/              # HTML templates
│   └── assets/             # CSS, JavaScript, images
├── config/
│   ├── routes.rb           # URL routing
│   └── database.yml        # Database configuration
├── db/
│   ├── migrate/            # Database migrations
│   └── seeds.rb            # Sample data
├── spec/                   # RSpec tests
│   ├── models/             # Model tests
│   ├── factories/          # Test data factories
│   └── support/            # Test helpers
└── Gemfile                 # Ruby dependencies
```

## Key Features

### 1. User Authentication
- Secure password hashing with bcrypt
- Session-based authentication
- Sign up, login, logout functionality

### 2. Gear Management
- Create and categorize hiking gear items
- Track weight, quantity, brand, price
- Mark items as consumable (food, fuel)
- View gear usage across trips

### 3. Trip Planning
- Create multiple trips with dates and locations
- Set target pack weight
- Add gear items to trips
- Track actual vs. target weight
- Visual weight status indicators

### 4. Weight Optimization
- Real-time weight calculations
- Color-coded weight status (under/close/over target)
- Sort gear by weight
- Filter by category
- Track total pack weight per trip

## Models Overview

### User
- Manages user authentication
- Has many trips and gear items
- Tracks total gear inventory

### Trip
- Represents a hiking trip
- Belongs to a user
- Has many gear items through trip_gears
- Calculates total weight and duration
- Tracks weight vs. target

### GearItem
- Individual piece of hiking gear
- Belongs to a user and optionally a category
- Used across multiple trips
- Tracks weight, quantity, brand

### GearCategory
- Organizes gear (Shelter, Cooking, Clothing, etc.)
- Pre-seeded with common categories

### TripGear (Join Model)
- Connects trips and gear items
- Tracks quantity per trip
- Allows marking items as packed

## Development Tips

### Adding New Features

1. **Create a migration:**
   ```bash
   rails generate migration AddFieldToModel field:type
   rails db:migrate
   ```

2. **Generate a new model:**
   ```bash
   rails generate model ModelName field:type
   ```

3. **Generate a controller:**
   ```bash
   rails generate controller ControllerName action1 action2
   ```

### Database Console

```bash
# Open Rails console
rails console

# Example queries
User.count
Trip.upcoming
GearItem.where(user: current_user).order(:weight)
```

### Customization

- **Change database to PostgreSQL:** Edit `Gemfile` and `config/database.yml`
- **Add authentication gem:** Consider using Devise for more features
- **Add authorization:** Consider using Pundit or CanCanCan
- **Add file uploads:** Consider using Active Storage for gear photos

## Production Deployment

Before deploying to production:

1. **Set environment variables:**
   ```bash
   export RAILS_ENV=production
   export SECRET_KEY_BASE=$(rails secret)
   ```

2. **Precompile assets:**
   ```bash
   RAILS_ENV=production rails assets:precompile
   ```

3. **Run migrations:**
   ```bash
   RAILS_ENV=production rails db:migrate
   ```

4. **Use a production server:**
   - Puma (included)
   - Passenger
   - Unicorn

5. **Database:**
   - Switch to PostgreSQL for production
   - Set up database backups

## Troubleshooting

### Common Issues

**Issue:** Bundle install fails
```bash
# Try updating bundler
gem install bundler
bundle update --bundler
```

**Issue:** Database migration errors
```bash
# Drop and recreate database
rails db:drop db:create db:migrate db:seed
```

**Issue:** Asset compilation fails
```bash
# Clear asset cache
rails assets:clobber
rails assets:precompile
```

**Issue:** Tests fail
```bash
# Ensure test database is set up
RAILS_ENV=test rails db:create db:migrate
```

## Next Steps

1. **Customize categories:** Edit `db/seeds.rb` with your preferred gear categories
2. **Add gear photos:** Implement Active Storage for gear images
3. **Export trip lists:** Add PDF or CSV export functionality
4. **Add packing lists:** Create printable packing checklists
5. **Weight recommendations:** Add AI-powered gear suggestions
6. **Share trips:** Allow users to share trip plans with others
7. **Mobile app:** Create a React Native or Flutter companion app

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Run RuboCop and fix any issues
6. Submit a pull request

## License

MIT License - feel free to use and modify for your needs!

## Support

For questions or issues:
- Check the README.md
- Review the code comments
- Run `rails routes` to see available endpoints
- Use `rails console` to debug issues

Happy hiking! ⛰️🎒
