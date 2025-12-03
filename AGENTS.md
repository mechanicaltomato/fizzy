# Fizzy

This file provides guidance to AI coding agents working with this repository.

## What is Fizzy?

Fizzy is a collaborative project management and issue tracking application built by 37signals/Basecamp. It's a kanban-style tool for teams to create and manage cards (tasks/issues) across boards, organize work into columns representing workflow stages, and collaborate via comments, mentions, and assignments.

## Development Commands

### Setup and Server
```bash
bin/setup              # Initial setup (installs gems, creates DB, loads schema)
bin/dev                # Start development server (runs on port 3006)
```

Development URL: http://fizzy.localhost:3006
Login with: david@37signals.com (development fixtures), password will appear in the browser console

### Testing
```bash
bin/rails test                    # Run unit tests (fast)
bin/rails test test/path/file_test.rb  # Run single test file
bin/rails test:system             # Run system tests (Capybara + Selenium)
bin/ci                            # Run full CI suite (style, security, tests)

# For parallel test execution issues, use:
PARALLEL_WORKERS=1 bin/rails test
```

CI pipeline (`bin/ci`) runs:
1. Rubocop (style)
2. Bundler audit (gem security)
3. Importmap audit
4. Brakeman (security scan)
5. Application tests
6. System tests

### Database
```bash
bin/rails db:fixtures:load   # Load fixture data
bin/rails db:migrate          # Run migrations
bin/rails db:reset            # Drop, create, and load schema
```

### Other Utilities
```bash
bin/rails dev:email          # Toggle letter_opener for email preview
bin/jobs                     # Manage Solid Queue jobs
bin/kamal deploy             # Deploy (requires 1Password CLI for secrets)
```

## Architecture Overview

### Multi-Tenancy (URL-Based)

Fizzy uses **URL path-based multi-tenancy**:
- Each Account (tenant) has a unique `external_account_id` (7+ digits)
- URLs are prefixed: `/{account_id}/boards/...`
- Middleware (`AccountSlug::Extractor`) extracts the account ID from the URL and sets `Current.account`
- The slug is moved from `PATH_INFO` to `SCRIPT_NAME`, making Rails think it's "mounted" at that path
- All models include `account_id` for data isolation
- Background jobs automatically serialize and restore account context

**Key insight**: This architecture allows multi-tenancy without subdomains or separate databases, making local development and testing simpler.

### Authentication & Authorization

**Passwordless magic link authentication**:
- Global `Identity` (email-based) can have `Users` in multiple Accounts
- Users belong to an Account and have roles: owner, admin, member, system
- Sessions managed via signed cookies
- Board-level access control via `Access` records

### Core Domain Models

**Account** → The tenant/organization
- Has users, boards, cards, tags, webhooks
- Has entropy configuration for auto-postponement

**Identity** → Global user (email)
- Can have Users in multiple Accounts
- Session management tied to Identity

**User** → Account membership
- Belongs to Account and Identity
- Has role (owner/admin/member/system)
- Board access via explicit `Access` records

**Board** → Primary organizational unit
- Has columns for workflow stages
- Can be "all access" or selective
- Can be published publicly with shareable key

**Card** → Main work item (task/issue)
- Sequential number within each Account
- Rich text description and attachments
- Lifecycle: triage → columns → closed/not_now
- Automatically postpones after inactivity ("entropy")

**Event** → Records all significant actions
- Polymorphic association to changed object
- Drives activity timeline, notifications, webhooks
- Has JSON `particulars` for action-specific data

### Entropy System

Cards automatically "postpone" (move to "not now") after inactivity:
- Account-level default entropy period
- Board-level entropy override
- Prevents endless todo lists from accumulating
- Configurable via Account/Board settings

### UUID Primary Keys

All tables use UUIDs (UUIDv7 format, base36-encoded as 25-char strings):
- Custom fixture UUID generation maintains deterministic ordering for tests
- Fixtures are always "older" than runtime records
- `.first`/`.last` work correctly in tests

### Background Jobs (Solid Queue)

Database-backed job queue (no Redis):
- Custom `FizzyActiveJobExtensions` prepended to ActiveJob
- Jobs automatically capture/restore `Current.account`
- Mission Control::Jobs for monitoring

Key recurring tasks (via `config/recurring.yml`):
- Deliver bundled notifications (every 30 min)
- Auto-postpone stale cards (hourly)
- Cleanup jobs for expired links, deliveries

### Sharded Full-Text Search

16-shard MySQL full-text search instead of Elasticsearch:
- Shards determined by account ID hash (CRC32)
- Search records denormalized for performance
- Models in `app/models/search/`

## Tools

### Chrome MCP (Local Dev)

URL: `http://fizzy.localhost:3006`
Login: david@37signals.com (passwordless magic link auth - check rails console for link)

Use Chrome MCP tools to interact with the running dev app for UI testing and debugging.

## Coding style

Please read the separate file `STYLE.md` for some guidance on coding style.

## AI Agent Documentation

For comprehensive guidance on working with this codebase, see these additional files:

### Core Documentation
- **`AI_DEVELOPMENT.md`** - Comprehensive guide for AI coding agents
  - Architecture patterns and best practices
  - Frontend/backend stack details
  - Extension points for new features
  - AI/LLM integration opportunities
  - Common pitfalls and solutions

- **`SETUP.md`** - Detailed local setup instructions
  - Prerequisites and installation
  - Database configuration (SQLite/MySQL)
  - Environment setup
  - Common troubleshooting
  - Useful command reference

- **`TESTING.md`** - Testing strategies and patterns
  - Unit, integration, and system tests
  - Test data with fixtures
  - Testing multi-tenancy
  - Performance testing
  - CI/CD integration

- **`EXTENSION_POINTS.md`** - Specific customization guides
  - AI/LLM feature examples (summarization, tagging, task breakdown)
  - Adding custom fields
  - External integrations (GitHub, Slack, Email)
  - UI customizations (Stimulus controllers, CSS)
  - Automation workflows
  - Analytics and reporting
  - API endpoints

### Claude Code Features

**Slash Commands** (`.claude/commands/`):
- `/setup` - Set up or reset development environment
- `/test` - Run test suite
- `/migrate` - Handle database migrations
- `/add-feature` - Guided feature addition
- `/ai-feature` - Add AI/LLM integration
- `/add-integration` - Add external service integration
- `/check-style` - Run Rubocop
- `/debug-issue` - Debug assistance
- `/explain-code` - Explain codebase concepts
- `/review-code` - Code quality review

## AI/LLM Integration Points

Fizzy has built-in support for AI features via `Card::Promptable`:

```ruby
# Format card for LLM consumption
card.to_prompt
# Returns structured text with title, description, metadata, assignees, etc.
```

**Recommended AI features to add:**
1. **Card Summarization** - Generate summaries from descriptions
2. **Smart Tagging** - Auto-suggest tags based on content
3. **Task Breakdown** - Generate checklist steps from descriptions
4. **Comment Analysis** - Extract action items, sentiment
5. **Priority Suggestions** - Recommend card priorities
6. **Similar Cards** - Find related cards using embeddings

See `EXTENSION_POINTS.md` for implementation examples.

## Key Patterns for AI Agents

### Multi-Tenancy is Critical
**Always scope queries to current account:**
```ruby
# ✅ Correct
Current.account.cards.find(id)

# ❌ Wrong - can access other accounts!
Card.find(id)
```

### Event Tracking
**Track all significant actions:**
```ruby
card.track_event "custom_action",
  particulars: { data: value }
```

### Background Jobs
**Use for slow operations (API calls, AI processing):**
```ruby
# Jobs automatically preserve Current.account
MyFeatureJob.perform_later(card)
```

### Real-Time Updates
**Use Turbo Streams for instant UI updates:**
```ruby
# Broadcast changes
card.broadcast_replace_to card

# In views
<%= turbo_stream_from @card %>
```

### Testing
**Write tests for all new features:**
```ruby
test "feature works correctly" do
  # Test with proper account scoping
end
```

## Common AI Agent Tasks

### Adding a New Feature
1. Read `EXTENSION_POINTS.md` for patterns
2. Create controller in appropriate namespace
3. Add routes (follow RESTful conventions)
4. Create model logic (use concerns for shared behavior)
5. Add views with Turbo Frames/Streams
6. Track events for audit trail
7. Write tests (unit + system)
8. Run `bundle exec rubocop` for style

### Adding AI Features
1. Use `card.to_prompt` for formatted input
2. Create service object or concern for AI logic
3. Add background job for async processing
4. Use Turbo Streams for real-time result updates
5. Handle errors gracefully (API timeouts, rate limits)
6. Add proper logging and monitoring
7. Write comprehensive tests with stubbed APIs

### Debugging Issues
1. Check logs: `tail -f log/development.log`
2. Verify account context: `Current.account`
3. Check background jobs: http://fizzy.localhost:3006/admin/jobs
4. Use Rails console: `bin/rails console`
5. Add breakpoints: `binding.break`
6. Review test failures for clues

## Important Codebase Conventions

### Model Organization
- Use concerns for shared behavior (`app/models/concerns/`)
- Order methods by invocation order
- Use explicit conditionals (not guard clauses)
- Delegate to models, not controllers

### Controller Organization
- Keep controllers shallow
- Use standard REST actions (avoid custom actions)
- Nested resources under parent (e.g., `cards/ai_summaries_controller.rb`)
- Track events in models, not controllers

### Frontend Organization
- Stimulus controllers for interactions (`app/javascript/controllers/`)
- Small, focused controllers with single responsibility
- Use data attributes for configuration
- Follow Hotwire patterns (Turbo Frames, Streams)

### Background Jobs
- Shallow job classes that delegate to models
- Pass objects, not IDs (account context preserved)
- Handle failures gracefully
- Add to `config/recurring.yml` for scheduled tasks

## Quick Reference

### File Locations
- Models: `app/models/`
- Controllers: `app/controllers/`
- Views: `app/views/`
- JavaScript: `app/javascript/controllers/`
- CSS: `app/assets/stylesheets/`
- Jobs: `app/jobs/`
- Tests: `test/`
- Routes: `config/routes.rb`
- Database: `db/schema.rb`

### Key Models to Understand
- `app/models/account.rb` - Tenant
- `app/models/user.rb` - Account member
- `app/models/card.rb` - Main domain object (24+ concerns!)
- `app/models/board.rb` - Workspace
- `app/models/event.rb` - Audit trail
- `app/models/current.rb` - Request context

### Development URLs
- App: http://fizzy.localhost:3006
- Jobs dashboard: http://fizzy.localhost:3006/admin/jobs
- Mailer previews: http://fizzy.localhost:3006/rails/mailers
- Health check: http://fizzy.localhost:3006/up

## Getting Started Checklist

When starting work on Fizzy:
1. [ ] Read this file (AGENTS.md)
2. [ ] Read `AI_DEVELOPMENT.md` for comprehensive overview
3. [ ] Run `bin/setup` to initialize environment
4. [ ] Run `bin/dev` to start server
5. [ ] Login with `david@37signals.com` (check console for code)
6. [ ] Explore the UI (create boards, cards, comments)
7. [ ] Run `bin/rails test` to verify tests pass
8. [ ] Read `EXTENSION_POINTS.md` for customization ideas
9. [ ] Review `STYLE.md` for coding conventions
10. [ ] Check `TESTING.md` before writing tests

## Need Help?

Use Claude Code slash commands:
- `/explain-code` - Understand specific files or concepts
- `/debug-issue` - Get help with errors
- `/add-feature` - Guided feature addition
- `/ai-feature` - Add AI capabilities

Or refer to documentation:
- Architecture questions → `AI_DEVELOPMENT.md`
- Setup issues → `SETUP.md`
- Testing questions → `TESTING.md`
- How to add features → `EXTENSION_POINTS.md`
- Code style → `STYLE.md`
