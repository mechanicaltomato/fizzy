# AI Development Guide for Fizzy

This guide provides comprehensive instructions for AI coding agents (like Claude Code) working with the Fizzy codebase.

## Quick Context

Fizzy is a production-grade Kanban board application by 37signals. It uses:
- **Rails 8 (edge)** running from main branch
- **Hotwire stack** (Turbo + Stimulus) - no build tools, instant feedback
- **Solid stack** (Queue, Cache, Cable) - database-backed, no Redis
- **Multi-tenant architecture** - URL path-based (`/{account_id}/...`)
- **UUID primary keys** (UUIDv7, base36-encoded)
- **SQLite by default** (MySQL supported for production)

## Key Architectural Patterns

### Multi-Tenancy
- Every request is scoped to an Account via `Current.account`
- Middleware extracts account ID from URL path: `/{account_id}/boards/...`
- All models include `account_id` for data isolation
- Background jobs automatically preserve account context
- **CRITICAL**: Always scope queries by current account

### Authentication
- **Passwordless magic links** (no passwords)
- `Identity` (global, email-based) → `Users` (account-scoped, role-based)
- Development login: `david@37signals.com` (check console for code)
- Sessions use signed cookies

### Event-Driven Architecture
- **Everything creates Events**: `Event` records track all significant actions
- Events drive: notifications, webhooks, activity timeline
- Pattern: `track_event "action_name", particulars: { data: value }`
- Location: `app/models/concerns/eventable.rb`

### Real-Time Updates (Turbo Streams)
- Changes broadcast automatically via Turbo Streams
- No manual WebSocket code needed
- Pattern: `turbo_stream_from @card` in views
- Backed by Solid Cable (database-backed WebSockets)

### Background Jobs (Solid Queue)
- Database-backed queue (no Redis)
- Custom extensions preserve `Current.account` context
- Mission Control dashboard: http://fizzy.localhost:3006/admin/jobs
- Pattern: Standard ActiveJob, context handled automatically

## Core Domain Models

```
Account (tenant)
  ├─ Users (members: owner/admin/member/system)
  ├─ Boards
  │   ├─ Columns (workflow stages)
  │   ├─ Cards
  │   │   ├─ Comments
  │   │   ├─ Attachments
  │   │   ├─ Steps (checklist items)
  │   │   ├─ Taggings → Tags
  │   │   ├─ Assignments → Users
  │   │   └─ Watches (subscriptions)
  │   └─ Webhooks (integrations)
  ├─ Events (audit trail)
  └─ Notifications (user alerts)
```

### Card Lifecycle States
- `drafted` → Newly created, in triage
- `triaged` → Moved to a column
- `postponed` → Moved to "Not Now"
- `closed` → Completed

### Entropy System
Cards automatically "postpone" (move to "Not Now") after inactivity:
- Configurable at Account and Board levels
- Prevents endless todo accumulation
- Runs hourly via `Card::AutoPostponer`

## Frontend Architecture

### Hotwire/Turbo
- **No build step** - Importmap for ES modules
- **Turbo Drive** - Instant page loads (PJAX-style)
- **Turbo Frames** - Lazy-loaded page sections
- **Turbo Streams** - Real-time updates (WebSocket-backed)

### Stimulus Controllers (56 total)
Location: `app/javascript/controllers/`

**Key controllers for customization:**
- `auto_save_controller.js` - Auto-saves forms
- `drag_and_drop_controller.js` - Card drag-and-drop
- `navigable_list_controller.js` - Keyboard navigation
- `hotkey_controller.js` - Keyboard shortcuts
- `notifications_controller.js` - Notification tray
- `syntax_highlight_controller.js` - Code highlighting

**Pattern to add new controller:**
```javascript
// app/javascript/controllers/my_feature_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  connect() {
    console.log("Controller connected")
  }

  doAction(event) {
    // Your logic
  }
}
```

Use in views:
```erb
<div data-controller="my-feature"
     data-my-feature-url-value="<%= some_path %>">
  <button data-action="click->my-feature#doAction">Click</button>
  <div data-my-feature-target="output"></div>
</div>
```

### Views Organization
- **ERB templates** with Turbo Frame/Stream patterns
- **Partials** heavily used for reusability
- **Concerns** in `app/views/concerns/` for shared helpers
- **ActionText** for rich text (cards, comments)
- **Lexxy** for rich text editing with prompts

### Styling
Location: `app/assets/stylesheets/`
- **Custom CSS** (no framework like Tailwind)
- 55+ CSS files, organized by component
- Utility classes in `utilities.css`
- Follow existing naming conventions

## Critical Files to Understand

### Models
- `app/models/account.rb` - Tenant/organization
- `app/models/user.rb` - Account member (with role)
- `app/models/board.rb` - Project/workspace
- `app/models/card.rb` - Task/issue (24+ concerns!)
- `app/models/event.rb` - Audit trail
- `app/models/current.rb` - Request-scoped context

### Controllers
- `app/controllers/concerns/authentication.rb` - Auth logic
- `app/controllers/concerns/authorization.rb` - Permissions
- `app/controllers/cards_controller.rb` - Main card CRUD
- `app/controllers/boards_controller.rb` - Board management

### Key Concerns
- `app/models/concerns/eventable.rb` - Event tracking
- `app/models/concerns/searchable.rb` - Full-text search
- `app/models/card/promptable.rb` - **AI integration point!**

### Configuration
- `config/routes.rb` - URL structure (nested resources)
- `config/initializers/tenanting/account_slug.rb` - Multi-tenancy
- `config/recurring.yml` - Scheduled background jobs

## AI/LLM Integration Opportunities

### Built-in AI Groundwork
**`Card::Promptable`** (app/models/card/promptable.rb):
```ruby
card.to_prompt
# Returns formatted card:
# "BEGIN OF CARD {id}
#  **Title:** ...
#  **Description:** ...
#  #### Metadata
#  * Created by: ...
#  * Assigned to: ...
#  * Board: ...
#  END OF CARD {id}"
```

**This suggests Fizzy is already considering AI features!**

### Recommended AI Extension Points

#### 1. Card Summarization
**Where:** `app/controllers/cards/ai_summaries_controller.rb`
```ruby
class Cards::AiSummariesController < ApplicationController
  def create
    @card = Card.find(params[:card_id])
    AiSummaryJob.perform_later(@card)
    # Return Turbo Stream to show loading state
  end
end
```

#### 2. Smart Tagging
**Where:** `app/models/card/ai_tagger.rb`
```ruby
class Card::AiTagger
  def suggest_tags(card)
    # Use card.to_prompt
    # Call LLM API
    # Return suggested tags
  end
end
```

#### 3. Task Breakdown
**Where:** Extend `app/models/step.rb` (checklist items)
```ruby
# Generate steps from card description
card.ai_generate_steps
```

#### 4. Comment Analysis
**Where:** `app/models/comment/analyzer.rb`
```ruby
# Sentiment, action items, blocking issues
```

## Extension Points by Feature Type

### Adding New Card Features

**1. Create nested resource controller:**
```ruby
# app/controllers/cards/my_feature_controller.rb
class Cards::MyFeatureController < ApplicationController
  before_action :set_card

  def create
    # Your logic
    @card.track_event "my_feature_added"
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @card }
    end
  end

  private
    def set_card
      @card = Card.find(params[:card_id])
    end
end
```

**2. Add route:**
```ruby
# config/routes.rb
resources :cards do
  scope module: :cards do
    resource :my_feature
  end
end
```

**3. Add view:**
```erb
<!-- app/views/cards/my_features/create.turbo_stream.erb -->
<%= turbo_stream.replace dom_id(@card) do %>
  <%= render @card %>
<% end %>
```

### Adding External Integrations

**Via Webhooks (Outbound):**
- Already built: Slack, Campfire, Basecamp, generic JSON
- Location: `app/models/webhook.rb`
- Events: `card_created`, `card_assigned`, `card_closed`, etc.
- Add new events: Update `PERMITTED_ACTIONS` in Webhook model

**Via API (Inbound):**
```ruby
# app/controllers/api/v1/cards_controller.rb
module Api
  module V1
    class CardsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_token

      def create
        @card = Current.account.cards.create!(card_params)
        render json: @card, status: :created
      end

      private
        def authenticate_api_token
          # Implement token auth
        end

        def card_params
          params.require(:card).permit(:title, :description)
        end
    end
  end
end
```

### Adding Background Jobs

```ruby
# app/jobs/my_feature_job.rb
class MyFeatureJob < ApplicationJob
  queue_as :default

  def perform(card)
    # Current.account is automatically set
    # Your logic here
  end
end
```

Jobs automatically preserve account context via custom ActiveJob extensions.

### Adding Database Fields

**1. Generate migration:**
```bash
bin/rails generate migration AddMyFieldToCards my_field:string
```

**2. Edit migration to include account_id index:**
```ruby
class AddMyFieldToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :my_field, :string
    add_index :cards, [:account_id, :my_field]
  end
end
```

**3. Run migration:**
```bash
bin/rails db:migrate
```

**4. Update model:**
```ruby
# app/models/card.rb
validates :my_field, presence: true, if: :some_condition
```

## Testing Strategies

### Running Tests
```bash
bin/rails test                     # Unit tests (fast)
bin/rails test:system              # System tests (Capybara)
bin/rails test test/path/file_test.rb  # Single file
bin/ci                             # Full CI suite
```

### Writing Tests

**Unit test pattern:**
```ruby
# test/models/card_test.rb
require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @card = @account.cards.first
  end

  test "should do something" do
    assert @card.valid?
  end
end
```

**System test pattern:**
```ruby
# test/system/cards_test.rb
require "application_system_test_case"

class CardsTest < ApplicationSystemTestCase
  test "creating a card" do
    visit root_path
    click_on "New Card"
    fill_in "Title", with: "Test Card"
    click_on "Create"
    assert_text "Test Card"
  end
end
```

### Test Data
- Fixtures in `test/fixtures/`
- Uses deterministic UUIDs
- Fixtures always "older" than runtime records

## Development Workflow

### Starting Development
```bash
bin/setup              # First time setup
bin/dev                # Start server (port 3006)
```

### Development URLs
- App: http://fizzy.localhost:3006
- Jobs dashboard: http://fizzy.localhost:3006/admin/jobs
- Mailer previews: http://fizzy.localhost:3006/rails/mailers
- Health check: http://fizzy.localhost:3006/up

### Login
- Email: `david@37signals.com`
- Check browser console for magic link code in development

### Database Commands
```bash
bin/rails db:reset           # Drop, create, load schema
bin/rails db:fixtures:load   # Load fixture data
bin/rails db:migrate         # Run pending migrations
```

### Debugging
- Use `binding.break` for breakpoints (Ruby 3.1+)
- Logs: `tail -f log/development.log`
- Console: `bin/rails console`
- Jobs: Check Mission Control at `/admin/jobs`

## Code Style Guidelines

See `STYLE.md` for detailed guidelines. Key points:

### Controllers
- Keep shallow (delegate to models)
- Use standard REST actions (avoid custom actions)
- Track events in models, not controllers

### Models
- Use concerns for shared behavior
- Order methods by invocation order
- Use explicit conditionals (not guard clauses)

### Views
- Use partials for reusability
- Turbo Frames for lazy loading
- Turbo Streams for updates

### JavaScript
- Stimulus controllers (not jQuery)
- Small, focused controllers
- Use data attributes for configuration

## Common Pitfalls

### Multi-Tenancy
❌ **DON'T:**
```ruby
Card.find(params[:id])  # Might access another account's data!
```

✅ **DO:**
```ruby
Current.account.cards.find(params[:id])  # Properly scoped
```

### Background Jobs
❌ **DON'T:**
```ruby
def perform(card_id)
  card = Card.find(card_id)  # Current.account not set!
end
```

✅ **DO:**
```ruby
def perform(card)
  # Pass the object, not ID
  # Account context preserved automatically
end
```

### Events
❌ **DON'T:**
```ruby
# In controller
Event.create!(...)
```

✅ **DO:**
```ruby
# In model
track_event "action_name", particulars: { data: value }
```

### UUIDs
❌ **DON'T:**
```ruby
Card.first  # Might not work as expected
```

✅ **DO:**
```ruby
Card.order(created_at: :asc).first  # Explicit ordering
```

## Useful Patterns from Codebase

### Tracking Events
```ruby
# In model after action
track_event "card_published",
  particulars: { board_id: board_id }
```

### Broadcasting Turbo Streams
```ruby
# Automatic via concerns
# Or manual:
broadcast_replace_to @card, target: "card_#{@card.id}"
```

### Scoping to Account
```ruby
# In model
belongs_to :account
default_scope { where(account_id: Current.account&.id) }
```

### Creating Notifications
```ruby
# Automatic via Notifiable concern
# Or manual:
Notifier.new(event).notify_watchers
```

## Resources

- **Hotwire Docs**: https://hotwired.dev
- **Stimulus Handbook**: https://stimulus.hotwired.dev/handbook/introduction
- **Rails Guides**: https://guides.rubyonrails.org
- **Mission Control Jobs**: https://github.com/rails/mission_control-jobs
- **Kamal**: https://kamal-deploy.org

## Getting Help

When stuck:
1. Search codebase for similar patterns (`grep -r "pattern"`)
2. Check test files for usage examples
3. Look at concerns for shared behavior
4. Review routes.rb for URL structure
5. Check initializers for configuration

## Next Steps

1. **Read**: `SETUP.md` for detailed local setup
2. **Read**: `EXTENSION_POINTS.md` for specific customization guides
3. **Read**: `TESTING.md` for testing strategies
4. **Explore**: Run the app and explore the UI
5. **Experiment**: Make a small change and see it work
