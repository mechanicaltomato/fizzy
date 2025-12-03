# Claude Code Configuration for Fizzy

This directory contains Claude Code-specific configuration and slash commands to enhance AI-assisted development.

## Available Slash Commands

Use these commands in Claude Code to get contextual help:

- **`/setup`** - Set up or reset the development environment
- **`/test`** - Run tests (unit, system, or full CI)
- **`/migrate`** - Handle database migrations
- **`/add-feature`** - Guided wizard for adding new features
- **`/ai-feature`** - Add AI/LLM integration features
- **`/add-integration`** - Add external service integrations
- **`/check-style`** - Run Rubocop style checker
- **`/debug-issue`** - Get debugging assistance
- **`/explain-code`** - Explain how specific code or features work
- **`/review-code`** - Review code for quality and best practices

## Documentation Index

### For AI Agents
- **`AGENTS.md`** - Quick reference for AI coding agents (root)
- **`AI_DEVELOPMENT.md`** - Comprehensive development guide (root)
- **`EXTENSION_POINTS.md`** - Specific customization examples (root)

### For Developers
- **`README.md`** - Project overview and basics (root)
- **`SETUP.md`** - Local setup instructions (root)
- **`TESTING.md`** - Testing strategies and patterns (root)
- **`STYLE.md`** - Code style guidelines (root)

## Quick Start

1. **Read the documentation:**
   ```bash
   # Start here for AI agents
   cat AGENTS.md

   # Comprehensive guide
   cat AI_DEVELOPMENT.md
   ```

2. **Set up the project:**
   ```bash
   bin/setup
   bin/dev
   ```

3. **Access the app:**
   - URL: http://fizzy.localhost:3006
   - Login: david@37signals.com (check console for code)

4. **Run tests:**
   ```bash
   bin/rails test    # Fast unit tests
   bin/ci            # Full CI suite
   ```

## Architecture Highlights

- **Rails 8 (edge)** - Running from main branch
- **Hotwire** - Turbo + Stimulus (no build tools!)
- **Solid Stack** - Database-backed (no Redis)
- **Multi-tenant** - URL path-based (`/{account_id}/...`)
- **UUIDs** - All primary keys (UUIDv7)
- **SQLite** - Default database (MySQL supported)

## AI/LLM Ready

Fizzy has built-in AI support:

```ruby
# Format card for LLM consumption
card.to_prompt
```

See `EXTENSION_POINTS.md` for examples of:
- Card summarization
- Smart tagging
- Task breakdown
- Comment analysis
- And more!

## Key Patterns

### Multi-Tenancy
```ruby
# ✅ Always scope to account
Current.account.cards.find(id)

# ❌ Never use global queries
Card.find(id)
```

### Event Tracking
```ruby
card.track_event "action_name",
  particulars: { data: value }
```

### Background Jobs
```ruby
# Account context preserved automatically
MyFeatureJob.perform_later(card)
```

### Turbo Streams
```ruby
# Real-time UI updates
card.broadcast_replace_to card
```

## Development Workflow

1. **Make changes** - Edit models, controllers, views
2. **Write tests** - Unit and system tests
3. **Check style** - `bundle exec rubocop`
4. **Run tests** - `bin/rails test`
5. **Manual test** - Use the browser
6. **Commit** - With descriptive message

## Resources

- **Hotwire**: https://hotwired.dev
- **Stimulus**: https://stimulus.hotwired.dev
- **Rails**: https://guides.rubyonrails.org
- **Mission Control**: https://github.com/rails/mission_control-jobs

## Need Help?

- Use slash commands (listed above)
- Check documentation files (in root)
- Review test files for examples
- Search codebase for patterns

Happy coding! 🚀
