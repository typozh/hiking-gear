# Ruby on Rails Development Environment on Raspberry Pi 4

This comprehensive guide walks you through setting up a complete Ruby on Rails development environment on a Raspberry Pi 4 using Raspberry Pi OS (64-bit) and modern best practices.

## Table of Contents

- [Prerequisites](#1-prerequisites)
- [Install Raspberry Pi OS](#2-install-raspberry-pi-os)
- [Initial System Setup](#3-initial-system-setup)
- [Install Development Dependencies](#4-install-development-dependencies)
- [Install rbenv and Ruby](#5-install-rbenv-and-ruby)
- [Install Rails](#6-install-rails)
- [Database Setup](#7-database-setup)
- [Create Your First Rails App](#8-create-your-first-rails-app)
- [Performance Tips](#9-performance-tips-for-raspberry-pi)
- [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

### 1.1. Hardware Requirements

- **Raspberry Pi 4** (2GB RAM minimum, 4-8GB recommended for Rails development)
- **32GB+ microSD card** (Class 10 or better) or external SSD via USB 3.0 (highly recommended for better performance)
- **Network connection** (Ethernet preferred for stability, Wi-Fi also works)
- **Power supply** (official USB-C power supply recommended)
- **Another computer** for initial setup and SSH access

### 1.2. Software Stack

This guide will set up:

- **Raspberry Pi OS (64-bit)** - Bookworm or later
- **rbenv** for Ruby version management
- **Ruby 3.3+** (latest stable version)
- **Rails 7.x** (latest stable version)
- **Node.js** and **Yarn** for JavaScript runtime and asset management
- **PostgreSQL** or **SQLite** as database
- **Git** for version control

---

## 2. Install Raspberry Pi OS

### 2.1. Download Raspberry Pi Imager

1. On your computer, download **Raspberry Pi Imager** from <https://www.raspberrypi.com/software/>
2. Install and launch the application

### 2.2. Flash Raspberry Pi OS

1. In Raspberry Pi Imager:
   - **Choose OS** → **Raspberry Pi OS (other)** → **Raspberry Pi OS (64-bit)** or **Raspberry Pi OS Lite (64-bit)** if you don't need a desktop
   - **Choose Storage** → select your microSD card
   
2. Click the **Settings** icon (gear icon) to configure advanced options:
   - Set hostname (e.g., `rails-pi`)
   - **Enable SSH** with password or public key authentication
   - Set **username** and **password** (e.g., user: `pi`)
   - Configure **Wi-Fi** if not using Ethernet
   - Set **locale settings** (timezone, keyboard layout)

3. Click **Write** and wait for the process to complete (5-10 minutes)

### 2.3. First Boot and SSH Connection

1. Insert the microSD card into your Raspberry Pi
2. Connect network cable (if using Ethernet) and power supply
3. Wait 2-3 minutes for the Pi to boot

4. Connect via SSH from your main computer:

   ```bash
   ssh pi@rails-pi.local
   # Or use IP address if .local doesn't work:
   # ssh pi@192.168.1.XXX
   ```

5. Accept the SSH fingerprint when prompted

---

## 3. Initial System Setup

### 3.1. Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

This may take 10-20 minutes on first run.

### 3.2. Install Essential Build Tools

```bash
sudo apt install -y git curl build-essential libssl-dev libreadline-dev \
  zlib1g-dev libyaml-dev libffi-dev libgdbm-dev libncurses5-dev \
  automake libtool bison
```

### 3.3. Configure Git (Optional)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 4. Install Development Dependencies

### 4.1. Install Node.js

Rails requires Node.js for JavaScript runtime and asset compilation:

```bash
# Install Node.js 20.x LTS (recommended for Rails)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify installation:

```bash
node --version  # Should show v20.x.x
npm --version
```

### 4.2. Install Yarn (Optional but Recommended)

```bash
sudo npm install -g yarn
yarn --version
```

### 4.3. Install Database Dependencies

Choose one or both depending on your needs:

**For SQLite (default Rails database, good for development):**

```bash
sudo apt install -y sqlite3 libsqlite3-dev
```

**For PostgreSQL (production-ready, recommended for serious projects):**

```bash
sudo apt install -y postgresql postgresql-contrib libpq-dev
```

---

## 5. Install rbenv and Ruby

### 5.1. Install rbenv

rbenv allows you to manage multiple Ruby versions easily:

```bash
# Clone rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv

# Add rbenv to PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc
```

### 5.2. Install ruby-build Plugin

```bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

### 5.3. Install Ruby

Check available Ruby versions:

```bash
rbenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -5
```

Install the latest stable Ruby (e.g., 3.3.0 - adjust version as needed):

```bash
# This will take 30-60 minutes on Raspberry Pi!
rbenv install 3.3.0

# Set as global default
rbenv global 3.3.0

# Verify installation
ruby --version  # Should show ruby 3.3.0
```

> **Note:** Ruby compilation is CPU-intensive and will take significant time on Raspberry Pi. Be patient!

### 5.4. Configure Bundler

```bash
gem install bundler
rbenv rehash
bundle --version
```

---

## 6. Install Rails

### 6.1. Install Rails Gem

```bash
# Install latest Rails
gem install rails

# Rehash rbenv shims
rbenv rehash

# Verify installation
rails --version  # Should show Rails 7.x.x
```

### 6.2. Install Additional Gems (Optional)

```bash
# Useful development gems
gem install pry pry-byebug
```

---

## 7. Database Setup

### 7.1. SQLite Setup

SQLite is installed by default with Rails. No additional configuration needed!

### 7.2. PostgreSQL Setup

If you installed PostgreSQL, configure it:

```bash
# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create a PostgreSQL user for Rails
sudo -u postgres createuser -s pi

# Create a password for the user
sudo -u postgres psql -c "ALTER USER pi WITH PASSWORD 'your_password';"
```

Test connection:

```bash
psql -U pi -d postgres -h localhost
# Type \q to exit
```

---

## 8. Create Your First Rails App

### 8.1. Create a New Rails Application

**With SQLite (default):**

```bash
cd ~
rails new myapp
cd myapp
```

**With PostgreSQL:**

```bash
cd ~
rails new myapp --database=postgresql
cd myapp

# Edit config/database.yml to add your PostgreSQL password
# Then create the database:
bin/rails db:create
```

### 8.2. Start the Rails Server

```bash
bin/rails server -b 0.0.0.0
```

The `-b 0.0.0.0` flag allows access from other computers on your network.

### 8.3. Access Your App

1. Find your Pi's IP address:
   ```bash
   hostname -I
   ```

2. From another computer on the same network, open:
   ```
   http://[raspberry-pi-ip]:3000
   ```

You should see the Rails welcome page! 🎉

---

## 9. Performance Tips for Raspberry Pi

### 9.1. Use an SSD Instead of SD Card

For significantly better performance, boot from a USB 3.0 SSD:

- Faster database operations
- Quicker gem installations
- Better overall responsiveness

### 9.2. Increase Swap Space

If you have limited RAM (2GB), increase swap:

```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE=100 to CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### 9.3. Optimize Ruby Installation

Use compile flags for better performance:

```bash
export RUBY_CONFIGURE_OPTS="--disable-install-doc --enable-shared"
rbenv install 3.3.0
```

### 9.4. Use Production Mode for Testing

When testing performance:

```bash
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails server
```

---

## 10. Troubleshooting

### 10.1. Ruby Installation Fails

**Problem:** Ruby compilation runs out of memory

**Solution:**
```bash
# Increase swap space (see section 9.2)
# Or use a pre-compiled Ruby version (not always available)
```

### 10.2. Can't Connect to PostgreSQL

**Problem:** Connection refused or authentication failed

**Solution:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify pg_hba.conf allows local connections
sudo nano /etc/postgresql/*/main/pg_hba.conf
# Ensure this line exists:
# local   all   all   md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### 10.3. Rails Server Not Accessible

**Problem:** Can't access Rails from another computer

**Solution:**
```bash
# Ensure you start with -b 0.0.0.0
bin/rails server -b 0.0.0.0

# Check firewall settings (usually not an issue on Raspberry Pi OS)
```

### 10.4. Gem Installation is Very Slow

**Problem:** Installing gems takes forever

**Solution:**
```bash
# Skip documentation to speed up gem installation
echo 'gem: --no-document' >> ~/.gemrc
```

### 10.5. Asset Compilation Fails

**Problem:** JavaScript/asset pipeline errors

**Solution:**
```bash
# Ensure Node.js is properly installed
node --version

# Try rebuilding node modules
cd your_app
rm -rf node_modules
yarn install
# or
npm install
```

---

## Additional Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [rbenv GitHub](https://github.com/rbenv/rbenv)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## Next Steps

1. **Learn Rails:** Work through the [Rails Getting Started Guide](https://guides.rubyonrails.org/getting_started.html)
2. **Set up version control:** Initialize a Git repository for your projects
3. **Deploy your app:** Consider deploying to a VPS or platform like Heroku/Render
4. **Join the community:** Participate in Rails forums and communities

Happy coding on your Raspberry Pi! 🚀
