# Deploying Hiking Gear Manager to Raspberry Pi

This guide walks you through deploying your Rails application to a Raspberry Pi 4 for local access on your home network.

## Prerequisites

- Raspberry Pi 4 with Ruby on Rails installed (follow [Install-linux-rbp.md](../Install-linux-rbp.md) first)
- SSH access to your Raspberry Pi
- Ruby 3.3+ and Rails 7+ installed on the Pi
- Your development machine with the application code
- GitHub SSH authentication set up (see below if using Git)

---

## Setting Up GitHub SSH Authentication (For Git Clone Method)

If you plan to use Git to deploy your code, set up SSH authentication to avoid entering passwords:

### On Your Raspberry Pi

```bash
# 1. Generate an SSH key pair
ssh-keygen -t ed25519 -C "your_email@example.com"

# Press Enter to accept the default file location (~/.ssh/id_ed25519)
# Enter a passphrase (optional but recommended) or press Enter to skip

# 2. Start the SSH agent
eval "$(ssh-agent -s)"

# 3. Add your SSH key to the agent
ssh-add ~/.ssh/id_ed25519

# 4. Display your public key to copy it
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output (starts with `ssh-ed25519` and ends with your email).

### On GitHub Website

1. Go to **github.com** → Click your profile picture → **Settings**
2. Click **SSH and GPG keys** (left sidebar)
3. Click **New SSH key**
4. Give it a title (e.g., "Raspberry Pi")
5. Paste your public key into the "Key" field
6. Click **Add SSH key**

### Test the Connection

```bash
# On Raspberry Pi
ssh -T git@github.com

# You should see: "Hi username! You've successfully authenticated..."
```

---

## Deployment Methods

Choose one of these methods based on your preference:

### Method 1: Git Clone (Recommended)

If your code is in a Git repository (GitHub, GitLab, etc.):

```bash
# On your Raspberry Pi (using SSH - make sure you've set up SSH keys first)
cd ~
git clone git@github.com:yourusername/hiking-gear.git
cd hiking-gear

# Or using HTTPS (will prompt for credentials)
git clone https://github.com/yourusername/hiking-gear.git
cd hiking-gear
```

### Method 2: Direct Copy via SCP

If you don't use Git, copy files directly from your computer:

```bash
# From your Windows machine (PowerShell)
# Replace 'pi' with your username and 'rails-pi.local' with your Pi's hostname/IP
scp -r C:\Users\typoz\OneDrive\dev\git\hiking-gear pi@rails-pi.local:~/

# From Linux/macOS
scp -r ~/path/to/hiking-gear pi@rails-pi.local:~/
```

### Method 3: Using rsync (Best for updates)

```bash
# From Linux/macOS/WSL
rsync -avz --exclude 'node_modules' --exclude 'tmp' --exclude 'log' \
  ~/path/to/hiking-gear/ pi@rails-pi.local:~/hiking-gear/

# From Windows (install rsync first via Chocolatey: choco install rsync)
rsync -avz --exclude 'node_modules' --exclude 'tmp' --exclude 'log' \
  /c/Users/typoz/OneDrive/dev/git/hiking-gear/ pi@rails-pi.local:~/hiking-gear/
```

---

## Installation Steps on Raspberry Pi

Once your code is on the Pi, SSH into it and follow these steps:

### 1. Navigate to Application Directory

```bash
ssh pi@rails-pi.local
cd ~/hiking-gear  # or whatever you named your directory
```

### 2. Install Dependencies

```bash
# First, install Ruby gems to generate Gemfile.lock
bundle install

# Commit the Gemfile.lock to version control
git add Gemfile.lock
git commit -m "Add Gemfile.lock for deployment"
git push

# Now configure deployment mode for production use (optional)
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# If you get memory issues, increase swap (see troubleshooting)
```

**Note:** The first `bundle install` creates `Gemfile.lock`. Deployment mode requires this file to exist first.

### 3. Set Up Secret Key and Database

Rails requires a secret key for production. Set it up first:

```bash
# Generate and set secret key (required for production)
export SECRET_KEY_BASE=$(rails secret)

# To make this permanent, add to ~/.bashrc
echo "export SECRET_KEY_BASE=$(rails secret)" >> ~/.bashrc
```

For SQLite (default, easiest):

```bash
# Create database directory
mkdir -p db

# Set up production database
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

For PostgreSQL (better for multi-user access):

```bash
# Create PostgreSQL database
sudo -u postgres createdb hiking_gear_production

# Edit config/database.yml (see PostgreSQL section below)

# Run migrations
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

### 4. Precompile Assets

```bash
RAILS_ENV=production rails assets:precompile
```

### 5. Test the Application

```bash
# Start the server (accessible only from Pi)
RAILS_ENV=production rails server

# Or start accessible from your network
RAILS_ENV=production rails server -b 0.0.0.0 -p 3000
```

Open browser on another device: `http://raspberry-pi-ip:3000`

Create your first user account at: `http://raspberry-pi-ip:3000/signup`

---

## Running as a Background Service

To keep the app running permanently, create a systemd service:

### 1. Create Service File

```bash
sudo nano /etc/systemd/system/hiking-gear.service
```

Add this content (adjust paths and username):

```ini
[Unit]
Description=Hiking Gear Manager Rails Application
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/hiking_gear_app
Environment="RAILS_ENV=production"
Environment="SECRET_KEY_BASE=YOUR_SECRET_KEY_HERE"
Environment="RAILS_SERVE_STATIC_FILES=true"
Environment="PORT=3000"

# Use Puma directly
ExecStart=/home/pi/.rbenv/shims/bundle exec puma -C config/puma.rb

# Restart policy
Restart=on-failure
RestartSec=10

# Logging
StandardOutput=append:/home/pi/hiking_gear_app/log/production.log
StandardError=append:/home/pi/hiking_gear_app/log/production.log

[Install]
WantedBy=multi-user.target
```

### 2. Create Puma Configuration

Create `config/puma.rb` if it doesn't exist:

```bash
nano config/puma.rb
```

Add:

```ruby
# Puma configuration for Raspberry Pi

# Number of threads (keep low for Pi)
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 2 }
threads threads_count, threads_count

# Port
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Bind to all interfaces
bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"

# PID file
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Workers (use 1 for Pi to save memory)
workers ENV.fetch("WEB_CONCURRENCY") { 1 }

# Preload app for better memory usage
preload_app!

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart
```

### 3. Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable hiking-gear

# Start the service
sudo systemctl start hiking-gear

# Check status
sudo systemctl status hiking-gear

# View logs
sudo journalctl -u hiking-gear -f
```

### 4. Manage the Service

```bash
# Stop the service
sudo systemctl stop hiking-gear

# Restart the service
sudo systemctl restart hiking-gear

# View recent logs
sudo journalctl -u hiking-gear -n 50

# Disable autostart
sudo systemctl disable hiking-gear
```

---

## Optional: Set Up Nginx Reverse Proxy

For better performance and to use port 80 (no :3000 in URL):

### 1. Install Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

### 2. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/hiking-gear
```

Add:

```nginx
upstream hiking_gear {
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  server_name rails-pi.local;  # Change to your Pi's hostname or IP
  
  root /home/pi/hiking_gear_app/public;
  
  # Log files
  access_log /var/log/nginx/hiking_gear_access.log;
  error_log /var/log/nginx/hiking_gear_error.log;
  
  # Serve static files directly
  location ~ ^/(assets|packs)/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }
  
  # Try to serve static files, otherwise proxy to app
  try_files $uri/index.html $uri @hiking_gear;
  
  location @hiking_gear {
    proxy_pass http://hiking_gear;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
  }
  
  # Error pages
  error_page 500 502 503 504 /500.html;
  client_max_body_size 4G;
  keepalive_timeout 10;
}
```

### 3. Enable Nginx Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/hiking-gear /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Enable Nginx on boot
sudo systemctl enable nginx
```

Now access your app at: `http://rails-pi.local` (no port number!)

---

## Database Configuration

### Using SQLite (Default - Easiest)

No additional configuration needed! Just make sure the database file has correct permissions:

```bash
chmod 644 db/production.sqlite3
```

### Using PostgreSQL (Better for Multiple Users)

Edit `config/database.yml`:

```yaml
production:
  adapter: postgresql
  encoding: unicode
  database: hiking_gear_production
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: pi
  password: <%= ENV["DATABASE_PASSWORD"] %>
  host: localhost
```

Set up PostgreSQL:

```bash
# Install PostgreSQL if not already installed
sudo apt install postgresql postgresql-contrib libpq-dev -y

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE hiking_gear_production;"
sudo -u postgres psql -c "CREATE USER pi WITH PASSWORD 'yourpassword';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE hiking_gear_production TO pi;"

# Add password to environment
echo 'export DATABASE_PASSWORD=yourpassword' >> ~/.bashrc
source ~/.bashrc
```

---

## Security Considerations

### 1. Firewall Setup

```bash
# Install UFW firewall
sudo apt install ufw -y

# Allow SSH
sudo ufw allow 22

# Allow HTTP (if using Nginx)
sudo ufw allow 80

# Allow Rails directly (if not using Nginx)
sudo ufw allow 3000

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### 2. Change Default User Password

```bash
passwd
```

### 3. Limit Network Access

If you only want local network access, make sure your router firewall blocks external access to port 3000 and 80.

### 4. Regular Updates

```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Update gems
cd ~/hiking_gear_app
bundle update --conservative
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
sudo systemctl restart hiking-gear
```

---

## Updating the Application

When you make changes to your app:

### Option 1: Git Pull

```bash
cd ~/hiking_gear_app
git pull origin main
bundle install
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
sudo systemctl restart hiking-gear
```

### Option 2: Copy Updated Files

```bash
# From your computer
rsync -avz --exclude 'node_modules' --exclude 'tmp' --exclude 'log' \
  /path/to/hiking_gear_app/ pi@rails-pi.local:~/hiking_gear_app/

# On the Pi
cd ~/hiking_gear_app
bundle install
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
sudo systemctl restart hiking-gear
```

---

## Accessing Your App

### From the Same Network

1. **Find your Pi's IP address:**
   ```bash
   hostname -I
   ```

2. **Access the app:**
   - With Nginx: `http://192.168.1.XXX`
   - Without Nginx: `http://192.168.1.XXX:3000`

3. **Or use hostname:**
   - `http://rails-pi.local` or `http://rails-pi.local:3000`

### From Outside Your Network (Advanced)

**Option 1: Tailscale VPN (Recommended)**

```bash
# Install Tailscale on Pi
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Install Tailscale on your devices
# Access via Tailscale IP from anywhere
```

**Option 2: Port Forwarding (Less Secure)**

- Configure your router to forward port 80 or 3000 to your Pi
- Use Dynamic DNS service (like DuckDNS) for your home IP
- ⚠️ Make sure to use HTTPS in production!

---

## Troubleshooting

### Bundle Install Runs Out of Memory

```bash
# Increase swap size
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE=100 to CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Try bundle install again
bundle install --jobs 1
```

### Database Permission Errors

```bash
# For SQLite
chmod 755 ~/hiking_gear_app/db
chmod 644 ~/hiking_gear_app/db/production.sqlite3

# For PostgreSQL
sudo -u postgres psql
# Then: GRANT ALL PRIVILEGES ON DATABASE hiking_gear_production TO pi;
```

### Service Won't Start

```bash
# Check logs
sudo journalctl -u hiking-gear -n 100

# Check if port is already in use
sudo lsof -i :3000

# Test manually first
cd ~/hiking_gear_app
RAILS_ENV=production rails server -b 0.0.0.0
```

### Assets Not Loading

```bash
# Recompile assets
cd ~/hiking_gear_app
RAILS_ENV=production rails assets:clobber
RAILS_ENV=production rails assets:precompile

# Check file permissions
ls -la public/assets/

# Make sure RAILS_SERVE_STATIC_FILES is set
export RAILS_SERVE_STATIC_FILES=true
```

### Can't Connect from Other Devices

```bash
# Check if server is listening on all interfaces
sudo netstat -tulpn | grep 3000

# Check firewall
sudo ufw status

# Try with IP address instead of hostname
# http://192.168.1.XXX:3000
```

### Slow Performance

```bash
# Reduce Puma workers and threads in config/puma.rb
workers 1
threads 2, 2

# Enable query caching in production
# Add to config/environments/production.rb:
# config.action_controller.perform_caching = true

# Restart service
sudo systemctl restart hiking-gear
```

---

## Performance Optimization for Raspberry Pi

### 1. Reduce Memory Usage

Edit `config/puma.rb`:

```ruby
# Use only 1 worker
workers 1

# Reduce threads
threads 1, 2
```

### 2. Enable Caching

Edit `config/environments/production.rb`:

```ruby
config.cache_store = :memory_store
config.action_controller.perform_caching = true
```

### 3. Use SSD Instead of SD Card

- Boot from USB SSD for much better performance
- Especially important for database operations

### 4. Optimize Database

For SQLite:

```bash
# Add to config/database.yml
production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
```

For PostgreSQL:

```bash
# Edit PostgreSQL config for limited resources
sudo nano /etc/postgresql/*/main/postgresql.conf

# Set:
# shared_buffers = 128MB
# effective_cache_size = 512MB
# maintenance_work_mem = 64MB
# work_mem = 4MB

sudo systemctl restart postgresql
```

---

## Backup Strategy

### Manual Backup

```bash
# Backup database (SQLite)
cp ~/hiking_gear_app/db/production.sqlite3 ~/backups/hiking_gear_$(date +%Y%m%d).sqlite3

# Backup database (PostgreSQL)
pg_dump hiking_gear_production > ~/backups/hiking_gear_$(date +%Y%m%d).sql
```

### Automatic Backup Script

```bash
# Create backup script
nano ~/backup_hiking_gear.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d_%H%M)
APP_DIR=~/hiking_gear_app

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
cp $APP_DIR/db/production.sqlite3 $BACKUP_DIR/db_$DATE.sqlite3

# Keep only last 7 backups
ls -t $BACKUP_DIR/db_*.sqlite3 | tail -n +8 | xargs rm -f

echo "Backup completed: $DATE"
```

Make executable and schedule:

```bash
chmod +x ~/backup_hiking_gear.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add: 0 2 * * * /home/pi/backup_hiking_gear.sh
```

---

## Monitoring

### Check App Status

```bash
# Service status
sudo systemctl status hiking-gear

# Recent logs
sudo journalctl -u hiking-gear -n 50

# Follow logs in real-time
sudo journalctl -u hiking-gear -f

# Check resource usage
htop
```

### Check Disk Space

```bash
df -h
du -sh ~/hiking_gear_app/*
```

### Check Memory Usage

```bash
free -h
```

---

## Next Steps

1. **Access your app** from any device on your network
2. **Create your user account** at `/signup`
3. **Start adding gear** to your inventory
4. **Plan your first trip**
5. **Set up automatic backups**
6. **Consider Tailscale** for remote access

Enjoy your self-hosted Hiking Gear Manager! 🏔️🎒

For questions or issues, check the logs:
```bash
sudo journalctl -u hiking-gear -f
tail -f ~/hiking_gear_app/log/production.log
```
