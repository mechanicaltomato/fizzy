# Fizzy Quick Start Guide

Get Fizzy running locally in 5 minutes.

## Prerequisites Check

```bash
# Check Ruby (need 3.3+)
ruby --version

# Check Bundler
gem install bundler

# Check Node (optional but recommended)
node --version
```

If you're missing any, see `SETUP.md` for installation instructions.

## 3-Step Setup

### 1. Install and Configure
```bash
# Install dependencies and set up database
bin/setup
```

This command:
- Installs all Ruby gems
- Creates SQLite databases
- Loads database schema
- Seeds with test data
- Prepares test environment

### 2. Start the Server
```bash
# Start development server
bin/dev
```

Server will run on port 3006.

### 3. Login
1. Open browser: http://fizzy.localhost:3006
2. Enter email: `david@37signals.com`
3. Check browser console (press F12, go to Console tab)
4. Look for: "Your magic link code: ABC123"
5. Enter the code

**You're in!** 🎉

## What to Explore

### Create Your First Board
1. Click "New Board"
2. Name it (e.g., "My Projects")
3. Add columns (e.g., "To Do", "In Progress", "Done")

### Create Cards
1. Click in a column to create a card
2. Give it a title
3. Add description (rich text with Markdown)
4. Drag cards between columns

### Try Features
- **Comments** - Collaborate on cards
- **Assignments** - Assign to yourself
- **Tags** - Organize cards
- **Steps** - Create checklists
- **Attachments** - Upload images
- **Keyboard shortcuts** - Press `?` to see all

## Verify Everything Works

```bash
# Run tests (should all pass)
bin/rails test
```

If tests pass, you're good to go!

## Next Steps

Now that it's running:

1. **For Development**:
   - Read `AI_DEVELOPMENT.md` for architecture overview
   - Read `EXTENSION_POINTS.md` for customization ideas
   - Read `STYLE.md` for coding conventions

2. **To Add Features**:
   - Use `/add-feature` slash command for guidance
   - Use `/ai-feature` for AI integration ideas
   - Check `EXTENSION_POINTS.md` for examples

3. **For Testing**:
   - Read `TESTING.md` for test patterns
   - Run `bin/rails test` frequently
   - Run `bin/ci` before committing

## Useful URLs

- **App**: http://fizzy.localhost:3006
- **Jobs Dashboard**: http://fizzy.localhost:3006/admin/jobs
- **Email Previews**: http://fizzy.localhost:3006/rails/mailers
- **Health Check**: http://fizzy.localhost:3006/up

## Common Commands

```bash
# Development
bin/dev                      # Start server
bin/rails console            # Rails console
tail -f log/development.log  # Watch logs

# Database
bin/rails db:migrate         # Run migrations
bin/rails db:reset           # Reset database
bin/rails db:fixtures:load   # Reload test data

# Testing
bin/rails test               # Unit tests
bin/rails test:system        # Browser tests
bin/ci                       # Full CI suite

# Code Quality
bundle exec rubocop          # Style check
bundle exec rubocop -a       # Auto-fix style
```

## Troubleshooting

### Port already in use?
```bash
lsof -i :3006
kill -9 <PID>
```

### Can't see magic link?
- Check browser console (F12 → Console)
- Or: `tail -f log/development.log | grep magic`
- Or: `bin/rails dev:email` to open emails in browser

### Database issues?
```bash
bin/setup --reset  # Full reset
```

### Tests failing?
```bash
PARALLEL_WORKERS=1 bin/rails test  # Run serially
```

## Need More Help?

- **Setup issues**: See `SETUP.md`
- **Architecture questions**: See `AI_DEVELOPMENT.md`
- **How to add features**: See `EXTENSION_POINTS.md`
- **Testing help**: See `TESTING.md`
- **In Claude Code**: Use slash commands like `/debug-issue`

## You're Ready! 🚀

Start exploring the codebase and building your customizations!

Key files to understand:
- `app/models/card.rb` - Main domain object
- `app/controllers/cards_controller.rb` - Card CRUD
- `app/views/cards/` - Card views
- `app/javascript/controllers/` - Stimulus controllers
- `config/routes.rb` - URL structure

Happy hacking!
