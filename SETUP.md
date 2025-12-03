# Fizzy Local Setup Guide

This guide provides step-by-step instructions for setting up Fizzy for local development.

## Prerequisites

### Required Software

#### Ruby
Fizzy requires Ruby 3.3+. Check your version:
```bash
ruby --version
```

**Install Ruby** (if needed):
- **macOS (Homebrew)**: `brew install ruby`
- **rbenv**: `rbenv install 3.3.0 && rbenv global 3.3.0`
- **asdf**: `asdf install ruby 3.3.0 && asdf global ruby 3.3.0`

#### Bundler
```bash
gem install bundler
```

#### Node.js (for asset compilation)
Fizzy uses Importmap (no npm/webpack), but Node is still needed for some tasks:
```bash
node --version  # 18+ recommended
```

**Install Node** (if needed):
- **macOS (Homebrew)**: `brew install node`
- **nvm**: `nvm install 20 && nvm use 20`

#### Database Options

**Option 1: SQLite (Default, Easiest)**
- Built into Ruby, no separate installation needed
- Perfect for local development
- Recommended for getting started

**Option 2: MySQL (Optional, for production-like setup)**
```bash
# macOS
brew install mysql
brew services start mysql

# Ubuntu/Debian
sudo apt-get install mysql-server libmysqlclient-dev

# Check it's running
mysql --version
```

## Initial Setup

### 1. Clone and Install Dependencies

If you haven't cloned yet:
```bash
git clone https://github.com/basecamp/fizzy.git
cd fizzy
```

Run the setup script (this does everything):
```bash
bin/setup
```

**What `bin/setup` does:**
- Installs Ruby gems (`bundle install`)
- Creates database
- Loads schema
- Seeds initial data with fixtures
- Prepares test database

### 2. Verify Installation

Check that everything installed correctly:
```bash
# Should show no errors
bin/rails runner "puts 'Rails loaded successfully'"

# Check database
bin/rails db:version

# Check gems
bundle check
```

## Running the Development Server

### Start the Server

```bash
bin/dev
```

This starts:
- **Puma** web server on port 3006
- **Solid Queue** worker for background jobs
- **Asset watchers** (if configured)

### Access the Application

Open your browser to:
```
http://fizzy.localhost:3006
```

**Note:** The app uses `.localhost` subdomain. This works natively in most browsers. If you have issues, try:
- `http://localhost:3006` (might work but breaks multi-tenancy URLs)
- Add to `/etc/hosts`: `127.0.0.1 fizzy.localhost`

### Login to Development Account

**Default development credentials:**
- Email: `david@37signals.com`
- Password: *None (passwordless auth)*

**How to login:**
1. Visit http://fizzy.localhost:3006
2. Enter email: `david@37signals.com`
3. Check **browser console** (F12 → Console tab)
4. Look for magic link code like: `Your magic link code: ABC123`
5. Enter the code

**Alternative:** Check Rails logs:
```bash
tail -f log/development.log
# Look for magic link in output
```

## Database Setup Options

### SQLite (Default)

Already configured by `bin/setup`. Database files located at:
- `storage/development.sqlite3`
- `storage/test.sqlite3`
- `storage/queue.sqlite3` (for Solid Queue)
- `storage/cache.sqlite3` (for Solid Cache)

### MySQL (Optional)

**1. Create MySQL user and databases:**
```bash
mysql -u root -p
```

```sql
CREATE USER 'fizzy'@'localhost' IDENTIFIED BY 'fizzy_password';
CREATE DATABASE fizzy_development;
CREATE DATABASE fizzy_test;
GRANT ALL PRIVILEGES ON fizzy_development.* TO 'fizzy'@'localhost';
GRANT ALL PRIVILEGES ON fizzy_test.* TO 'fizzy'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**2. Configure database.yml:**
```bash
# Option 1: Set environment variable (temporary)
export DATABASE_ADAPTER=mysql
export DATABASE_URL="mysql2://fizzy:fizzy_password@localhost/fizzy_development"

# Option 2: Edit config/database.yml directly
# (see config/database.yml for examples)
```

**3. Setup with MySQL:**
```bash
DATABASE_ADAPTER=mysql bin/setup --reset
```

**4. Run server with MySQL:**
```bash
DATABASE_ADAPTER=mysql bin/dev
```

## Configuration

### Environment Variables

Create `.env` file (optional) for local configuration:
```bash
# .env
DATABASE_ADAPTER=sqlite3  # or mysql
RAILS_ENV=development
REDIS_URL=redis://localhost:6379  # Not used by default (Solid stack)

# Web Push Notifications (optional for development)
# VAPID_PRIVATE_KEY=your_key
# VAPID_PUBLIC_KEY=your_key

# Storage (optional, uses local disk by default)
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_REGION=us-east-1
# AWS_BUCKET=
```

### Email Configuration

**Development mode** automatically captures emails without sending.

**View sent emails:**
```bash
bin/rails dev:email  # Enable letter_opener
# Now emails open in browser automatically

bin/rails dev:email  # Run again to disable
```

**View email previews:**
Visit: http://fizzy.localhost:3006/rails/mailers

### Web Push Notifications (Optional)

Generate VAPID keys for browser push notifications:
```bash
bin/rails console
```

```ruby
vapid_key = WebPush.generate_key
puts "VAPID_PRIVATE_KEY=#{vapid_key.private_key}"
puts "VAPID_PUBLIC_KEY=#{vapid_key.public_key}"
```

Add to `.env` or export as environment variables.

## Resetting the Database

**Full reset** (drops, creates, loads schema and seeds):
```bash
bin/setup --reset
```

**Or manually:**
```bash
bin/rails db:drop db:create db:schema:load db:fixtures:load
```

## Loading Fixture Data

Fixtures provide test data for development:
```bash
bin/rails db:fixtures:load
```

**Available fixtures:**
- Accounts (organizations)
- Users (david@37signals.com and others)
- Boards (sample projects)
- Cards (sample tasks)
- Comments, tags, etc.

## Running Tests

### Quick Tests (Unit only)
```bash
bin/rails test
```

### System Tests (Browser-based)
```bash
bin/rails test:system
```

**Requirements for system tests:**
- Chrome browser
- ChromeDriver (installed automatically via selenium-webdriver gem)

### Full CI Suite
```bash
bin/ci
```

**Runs:**
1. Rubocop (code style)
2. Bundle audit (security)
3. Importmap audit
4. Brakeman (security scanner)
5. All tests (unit + system)

### Test with MySQL
```bash
DATABASE_ADAPTER=mysql bin/ci
```

## Development Tools

### Rails Console
```bash
bin/rails console
# or
bin/rails c
```

**Useful commands:**
```ruby
# Get current account (in request context, won't work in console)
Current.account

# Find records
Account.first
User.find_by(email: "david@37signals.com")
Card.last

# Create test data
account = Account.first
card = account.cards.create!(
  title: "Test Card",
  creator: account.users.first
)
```

### Database Console
```bash
# SQLite
bin/rails dbconsole
# or
sqlite3 storage/development.sqlite3

# MySQL
mysql -u fizzy -p fizzy_development
```

### View Logs
```bash
# Development log
tail -f log/development.log

# Test log
tail -f log/test.log

# Clear logs
bin/rails log:clear
```

### Background Jobs Dashboard

Visit: http://fizzy.localhost:3006/admin/jobs

**Mission Control::Jobs** provides:
- Job queue status
- Failed jobs
- Job history
- Retry capabilities

### Asset Pipeline

Fizzy uses **Propshaft** (modern asset pipeline) and **Importmap** (JS modules):

**Precompile assets** (usually not needed in development):
```bash
bin/rails assets:precompile
```

**Clear assets:**
```bash
bin/rails assets:clobber
```

### Debugging

**Add breakpoints** in code:
```ruby
binding.break  # Ruby 3.1+
# or
debugger
```

When hit, you'll drop into an interactive debug console.

**Debug with VS Code:**
1. Install "Ruby LSP" extension
2. Set breakpoints in editor
3. Run with debug configuration

## Common Issues

### Port Already in Use

If port 3006 is taken:
```bash
# Find process
lsof -i :3006

# Kill it
kill -9 <PID>

# Or use different port
bin/rails server -p 3007
```

### Database Migration Issues

```bash
# Check migration status
bin/rails db:migrate:status

# Rollback last migration
bin/rails db:rollback

# Rollback to specific version
bin/rails db:migrate:down VERSION=20240101120000

# Fresh start
bin/setup --reset
```

### Gem Installation Issues

```bash
# Update bundler
gem install bundler

# Clean and reinstall
bundle clean --force
bundle install

# Platform-specific gems (M1/M2 Mac)
bundle lock --add-platform arm64-darwin
bundle install
```

### MySQL Connection Issues

```bash
# Check MySQL is running
mysql.server status  # or: brew services list

# Test connection
mysql -u fizzy -p

# Reset permissions
mysql -u root -p
GRANT ALL PRIVILEGES ON *.* TO 'fizzy'@'localhost';
FLUSH PRIVILEGES;
```

### Magic Link Not Showing

If you don't see the magic link code:

**Option 1: Check console**
- Open browser DevTools (F12)
- Go to Console tab
- Look for "Your magic link code: ..."

**Option 2: Check logs**
```bash
tail -f log/development.log | grep magic
```

**Option 3: Enable letter_opener**
```bash
bin/rails dev:email
# Click magic link in opened email
```

### Localhost Domain Not Working

If `fizzy.localhost` doesn't work:

**Option 1: Use plain localhost**
```
http://localhost:3006
```
Note: This might break multi-tenancy URLs.

**Option 2: Edit /etc/hosts**
```bash
sudo nano /etc/hosts
```
Add:
```
127.0.0.1 fizzy.localhost
```

**Option 3: Use lvh.me** (public DNS that resolves to localhost)
```
http://fizzy.lvh.me:3006
```

## File Structure Overview

```
fizzy/
├── app/
│   ├── controllers/        # Request handlers
│   ├── models/            # Domain logic
│   ├── views/             # ERB templates
│   ├── javascript/        # Stimulus controllers
│   ├── assets/            # CSS, images
│   ├── jobs/              # Background jobs
│   └── mailers/           # Email templates
├── config/
│   ├── routes.rb          # URL structure
│   ├── database.yml       # DB configuration
│   ├── initializers/      # App initialization
│   └── recurring.yml      # Scheduled jobs
├── db/
│   ├── migrate/           # Database migrations
│   └── schema.rb          # Current DB structure
├── test/
│   ├── models/            # Model tests
│   ├── controllers/       # Controller tests
│   ├── system/            # Browser tests
│   └── fixtures/          # Test data
├── storage/               # SQLite databases, uploads
├── bin/                   # Executable scripts
│   ├── setup              # Initial setup
│   ├── dev                # Start dev server
│   └── ci                 # Run CI suite
└── tmp/                   # Temporary files, cache
```

## Next Steps

1. **Verify everything works:**
   ```bash
   bin/dev
   # Visit http://fizzy.localhost:3006
   # Login with david@37signals.com
   ```

2. **Explore the UI:**
   - Create a board
   - Add cards
   - Move cards between columns
   - Add comments
   - Try keyboard shortcuts

3. **Run tests:**
   ```bash
   bin/rails test
   ```

4. **Read documentation:**
   - `AI_DEVELOPMENT.md` - Comprehensive development guide
   - `EXTENSION_POINTS.md` - Where to add features
   - `TESTING.md` - Testing strategies
   - `STYLE.md` - Code style guidelines

5. **Make your first change:**
   - Try adding a field to cards
   - Customize the UI
   - Add a new Stimulus controller

## Useful Commands Cheat Sheet

```bash
# Setup
bin/setup                    # Initial setup
bin/setup --reset            # Full reset

# Server
bin/dev                      # Start development server
bin/rails s -p 3007          # Custom port

# Database
bin/rails db:migrate         # Run migrations
bin/rails db:rollback        # Undo last migration
bin/rails db:reset           # Drop, create, load schema
bin/rails db:fixtures:load   # Load test data

# Testing
bin/rails test               # Unit tests
bin/rails test:system        # Browser tests
bin/ci                       # Full CI suite

# Console
bin/rails console            # Interactive Ruby
bin/rails dbconsole          # Database console

# Jobs
# Visit: http://fizzy.localhost:3006/admin/jobs

# Code Quality
bundle exec rubocop          # Style checker
bundle exec brakeman         # Security scanner

# Email
bin/rails dev:email          # Toggle letter_opener
# Visit: http://fizzy.localhost:3006/rails/mailers

# Logs
tail -f log/development.log  # Watch logs
bin/rails log:clear          # Clear logs
```

## Getting Help

- **Documentation**: See `AI_DEVELOPMENT.md`
- **Tests**: Check test files for usage examples
- **Issues**: https://github.com/basecamp/fizzy/issues
- **Rails Guides**: https://guides.rubyonrails.org
- **Hotwire Docs**: https://hotwired.dev
