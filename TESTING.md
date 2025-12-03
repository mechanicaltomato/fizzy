# Testing Guide for Fizzy

This guide covers testing strategies, patterns, and best practices for the Fizzy application.

## Test Suite Overview

Fizzy uses Rails' built-in testing framework (Minitest) with three types of tests:

1. **Unit Tests** - Models, helpers, concerns (fast, no browser)
2. **Controller/Integration Tests** - Request handling (fast, no browser)
3. **System Tests** - End-to-end browser tests (slower, Capybara + Selenium)

## Running Tests

### Quick Feedback Loop
```bash
bin/rails test
```
Runs unit and integration tests only (fast, typically <1 minute).

### System Tests
```bash
bin/rails test:system
```
Runs browser-based tests (slower, ~5-10 minutes).

### Full CI Suite
```bash
bin/ci
```
Runs everything:
1. Rubocop (style checking)
2. Bundle audit (gem security)
3. Importmap audit
4. Brakeman (security scanning)
5. Unit tests
6. System tests

### Single File
```bash
bin/rails test test/models/card_test.rb
```

### Single Test
```bash
bin/rails test test/models/card_test.rb:42
```
(Line number of the test)

### With Coverage
```bash
COVERAGE=true bin/rails test
```

### Different Database
```bash
DATABASE_ADAPTER=mysql bin/rails test
```

### Parallel Execution
```bash
# Default (uses multiple workers)
bin/rails test

# Single worker (for debugging)
PARALLEL_WORKERS=1 bin/rails test
```

## Test Structure

### File Organization
```
test/
├── models/              # Model unit tests
├── controllers/         # Controller tests
├── system/             # Browser-based tests
├── jobs/               # Background job tests
├── mailers/            # Email tests
├── helpers/            # Helper method tests
├── integration/        # Multi-request tests
├── fixtures/           # Test data
└── test_helper.rb      # Test configuration
```

## Writing Unit Tests

### Model Test Pattern
```ruby
# test/models/card_test.rb
require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @card = @account.cards.first
    @user = @account.users.first
  end

  test "should require title" do
    card = @account.cards.build(title: nil)
    assert_not card.valid?
    assert_includes card.errors[:title], "can't be blank"
  end

  test "should track event when published" do
    assert_difference -> { @card.events.count }, 1 do
      @card.publish!
    end
  end

  test "should scope to account" do
    other_account = accounts(:two)
    assert_not_equal @account.cards.count, other_account.cards.count
  end

  test "should generate prompt format" do
    prompt = @card.to_prompt
    assert_includes prompt, "BEGIN OF CARD"
    assert_includes prompt, @card.title
    assert_includes prompt, "END OF CARD"
  end
end
```

### Key Patterns

**Use fixtures for setup:**
```ruby
@card = cards(:important)  # From fixtures
```

**Test account scoping:**
```ruby
test "should not access other account data" do
  other_card = accounts(:two).cards.first
  assert_raises(ActiveRecord::RecordNotFound) do
    @account.cards.find(other_card.id)
  end
end
```

**Test event tracking:**
```ruby
test "should track assignment event" do
  assert_difference -> { Event.count }, 1 do
    @card.assign!(@user)
  end

  event = Event.last
  assert_equal "card_assigned", event.action
  assert_equal @card, event.eventable
end
```

**Test concerns:**
```ruby
# Test a concern in isolation
test "eventable concern tracks events" do
  assert_respond_to @card, :track_event
  @card.track_event "custom_action"
  assert_equal "custom_action", Event.last.action
end
```

## Writing Controller Tests

### Controller Test Pattern
```ruby
# test/controllers/cards_controller_test.rb
require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = @account.users.first
    @card = @account.cards.first

    # Simulate login
    login_as @user
  end

  test "should get index" do
    get account_cards_url(@account)
    assert_response :success
  end

  test "should create card" do
    assert_difference -> { @account.cards.count }, 1 do
      post account_cards_url(@account), params: {
        card: {
          title: "New Card",
          description: "Description"
        }
      }
    end

    assert_redirected_to card_url(Card.last)
  end

  test "should not access other account cards" do
    other_card = accounts(:two).cards.first

    get card_url(other_card)
    assert_response :not_found  # or :forbidden
  end

  test "should respond with turbo stream" do
    post account_cards_url(@account),
      params: { card: { title: "Test" } },
      as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.body
  end
end
```

### Helper Methods

**Login simulation:**
```ruby
# test/test_helper.rb
def login_as(user)
  post session_url, params: {
    email: user.identity.email
  }
  # Or directly set session
  session[:user_id] = user.id
end
```

**Account context:**
```ruby
def with_account(account)
  Current.account = account
  yield
ensure
  Current.account = nil
end
```

## Writing System Tests

### System Test Pattern
```ruby
# test/system/cards_test.rb
require "application_system_test_case"

class CardsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
    @user = @account.users.first
    login_as @user
  end

  test "creating a card" do
    visit root_url

    click_on "New Card"

    fill_in "Title", with: "System Test Card"
    fill_in "Description", with: "This is a test"

    click_on "Create Card"

    assert_text "System Test Card"
    assert_text "Card was successfully created"
  end

  test "drag and drop card between columns" do
    visit board_url(@account.boards.first)

    card = find(".card", text: "Important Task")
    target_column = find(".column", text: "In Progress")

    card.drag_to(target_column)

    # Wait for Turbo Stream update
    assert_selector ".column .card", text: "Important Task"
  end

  test "real-time updates" do
    using_session :user1 do
      login_as @user
      visit board_url(@account.boards.first)
    end

    using_session :user2 do
      other_user = @account.users.second
      login_as other_user
      visit board_url(@account.boards.first)

      # Create card in this session
      click_on "New Card"
      fill_in "Title", with: "Real-time Card"
      click_on "Create"
    end

    using_session :user1 do
      # Should see the card appear via Turbo Stream
      assert_text "Real-time Card"
    end
  end

  test "keyboard navigation" do
    visit board_url(@account.boards.first)

    # Press 'c' to create card
    page.send_keys("c")
    assert_selector "#new_card_modal"

    # Press 'Escape' to close
    page.send_keys(:escape)
    assert_no_selector "#new_card_modal"
  end
end
```

### System Test Best Practices

**Wait for asynchronous updates:**
```ruby
# Bad - might fail randomly
assert_text "Updated"

# Good - waits up to default timeout
assert_selector ".card", text: "Updated"

# Good - custom timeout
assert_text "Updated", wait: 5
```

**Handle Turbo navigation:**
```ruby
# Turbo Drive intercepts clicks
click_on "Link"

# If needed, disable Turbo for specific tests
page.driver.browser.execute_script("Turbo.session.drive = false")
```

**Multiple browser sessions:**
```ruby
using_session :user1 do
  # Actions in first browser
end

using_session :user2 do
  # Actions in second browser
end
```

**Take screenshots on failure:**
```ruby
# Automatic in system tests
# Screenshots saved to tmp/screenshots/
```

**Debug with pause:**
```ruby
test "something" do
  visit root_url
  binding.break  # Pauses and opens browser
  click_on "Button"
end
```

## Testing Background Jobs

### Job Test Pattern
```ruby
# test/jobs/card/ai_summary_job_test.rb
require "test_helper"

class Card::AiSummaryJobTest < ActiveJob::TestCase
  setup do
    @account = accounts(:one)
    @card = @account.cards.first
  end

  test "should enqueue job" do
    assert_enqueued_with(job: Card::AiSummaryJob) do
      Card::AiSummaryJob.perform_later(@card)
    end
  end

  test "should process card" do
    # Perform job immediately
    perform_enqueued_jobs do
      Card::AiSummaryJob.perform_later(@card)
    end

    # Assert results
    @card.reload
    assert_not_nil @card.ai_summary
  end

  test "should preserve account context" do
    perform_enqueued_jobs do
      Card::AiSummaryJob.perform_later(@card)
    end

    # Job should have access to correct account
    assert_equal @account, @card.account
  end

  test "should handle errors gracefully" do
    # Stub API to raise error
    stub_api_error

    assert_nothing_raised do
      perform_enqueued_jobs do
        Card::AiSummaryJob.perform_later(@card)
      end
    end
  end
end
```

## Testing Mailers

### Mailer Test Pattern
```ruby
# test/mailers/notification_mailer_test.rb
require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "card assigned email" do
    card = cards(:important)
    user = users(:david)

    email = NotificationMailer.card_assigned(card, user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal "Card assigned: #{card.title}", email.subject
    assert_match card.title, email.body.encoded
  end

  test "email has correct links" do
    card = cards(:important)
    user = users(:david)

    email = NotificationMailer.card_assigned(card, user)

    assert_match card_url(card), email.body.encoded
    assert_match "View Card", email.body.encoded
  end
end
```

## Testing Webhooks

### Webhook Test Pattern
```ruby
# test/models/webhook_test.rb
require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  setup do
    @webhook = webhooks(:slack)
    @card = cards(:important)
  end

  test "should deliver webhook" do
    stub_request(:post, @webhook.url)
      .to_return(status: 200, body: "ok")

    @webhook.deliver(
      action: "card_created",
      card: @card
    )

    assert_requested :post, @webhook.url
  end

  test "should include HMAC signature" do
    stub = stub_request(:post, @webhook.url)

    @webhook.deliver(action: "card_created", card: @card)

    assert_requested stub do |req|
      assert_not_nil req.headers["X-Fizzy-Signature"]
    end
  end

  test "should handle webhook failure" do
    stub_request(:post, @webhook.url)
      .to_return(status: 500)

    assert_difference -> { @webhook.deliveries.failed.count }, 1 do
      @webhook.deliver(action: "card_created", card: @card)
    end
  end
end
```

## Testing Turbo Streams

### Turbo Stream Test Pattern
```ruby
# test/controllers/cards_controller_test.rb
test "update broadcasts turbo stream" do
  patch card_url(@card),
    params: { card: { title: "Updated" } },
    as: :turbo_stream

  assert_response :success
  assert_turbo_stream action: "replace", target: dom_id(@card)
end

# Custom assertion helper
def assert_turbo_stream(action:, target:)
  assert_match %r{<turbo-stream action="#{action}" target="#{target}">},
               response.body
end
```

## Testing Search

### Search Test Pattern
```ruby
# test/models/user/searcher_test.rb
require "test_helper"

class User::SearcherTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)
    @account = @user.account

    # Ensure search index is up to date
    Card.where(account: @account).each(&:reindex_search)
  end

  test "should find cards by title" do
    results = User::Searcher.new(@user).search("Important")

    assert_includes results, cards(:important)
  end

  test "should not find cards from other accounts" do
    other_card = accounts(:two).cards.first

    results = User::Searcher.new(@user).search(other_card.title)

    assert_not_includes results, other_card
  end

  test "should search in description" do
    card = @account.cards.create!(
      title: "Test",
      description: "Unique search term xyz123"
    )
    card.reindex_search

    results = User::Searcher.new(@user).search("xyz123")
    assert_includes results, card
  end
end
```

## Fixtures

### Creating Fixtures
```yaml
# test/fixtures/cards.yml
important:
  id: <%= UuidPrimaryKey.to_uuid("card_1") %>
  account: one
  board: development
  title: "Important Task"
  description: "This is very important"
  creator: david
  state: triaged
  created_at: <%= 1.day.ago %>
  updated_at: <%= 1.hour.ago %>

urgent:
  id: <%= UuidPrimaryKey.to_uuid("card_2") %>
  account: one
  board: development
  title: "Urgent Bug"
  description: "Fix this ASAP"
  creator: david
  state: triaged
  created_at: <%= 2.days.ago %>
```

### Using Fixtures
```ruby
# Access by name
@card = cards(:important)

# Access associations
@card.creator  # Returns users(:david)
@card.board    # Returns boards(:development)

# Access all fixtures
Card.all  # Returns all card fixtures
```

### Fixture Best Practices
- Use descriptive names (`:important`, not `:card1`)
- Use UUIDs for IDs (maintains deterministic ordering)
- Set up realistic relationships
- Include edge cases (nil values, empty strings, etc.)
- Keep fixtures focused and minimal

## Test Helpers

### Common Test Helpers
```ruby
# test/test_helper.rb

# Login helper
def login_as(user)
  post session_url, params: {
    identity: { email: user.identity.email }
  }
  follow_redirect!
end

# Account context helper
def with_account(account)
  original = Current.account
  Current.account = account
  yield
ensure
  Current.account = original
end

# Stub external API
def stub_llm_api(response: "AI generated response")
  stub_request(:post, "https://api.openai.com/v1/completions")
    .to_return(
      status: 200,
      body: { choices: [{ text: response }] }.to_json
    )
end

# Wait for Solid Queue jobs
def wait_for_jobs
  10.times do
    break if SolidQueue::Job.pending.count.zero?
    sleep 0.1
  end
end

# Create test account
def create_test_account(name: "Test Account")
  Account.create!(
    name: name,
    external_account_id: SecureRandom.random_number(10_000_000)
  )
end
```

## Mocking and Stubbing

### Using Mocha
```ruby
# test/test_helper.rb
require "mocha/minitest"

# In tests
test "should call external service" do
  ExternalService.expects(:call).with(@card).returns(true)

  @card.process_externally
end

test "should handle service failure" do
  ExternalService.stubs(:call).raises(StandardError)

  assert_nothing_raised do
    @card.process_externally
  end
end
```

### Using WebMock (for HTTP)
```ruby
test "should call webhook" do
  stub = stub_request(:post, "https://example.com/webhook")
    .with(
      body: hash_including(action: "card_created"),
      headers: { "Content-Type" => "application/json" }
    )
    .to_return(status: 200)

  @webhook.deliver(action: "card_created", card: @card)

  assert_requested stub
end
```

## Performance Testing

### Detecting N+1 Queries
```ruby
test "should not have N+1 queries" do
  # Warm up
  @board.cards.includes(:assignees, :tags).to_a

  # Count queries
  queries = count_queries do
    @board.cards.includes(:assignees, :tags).each do |card|
      card.assignees.to_a
      card.tags.to_a
    end
  end

  # Should be constant regardless of card count
  assert_operator queries, :<, 5
end

def count_queries
  count = 0
  callback = ->(*, payload) { count += 1 unless payload[:name] == "CACHE" }
  ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
    yield
  end
  count
end
```

## Test Coverage

### Generating Coverage Reports
```bash
COVERAGE=true bin/rails test
```

### Viewing Coverage
```bash
open coverage/index.html
```

### Coverage Goals
- **Models**: 90%+ coverage
- **Controllers**: 80%+ coverage
- **Critical paths**: 100% coverage
- **Overall**: 85%+ coverage

## Continuous Integration

### CI Configuration
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        database: [sqlite3, mysql]

    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Run tests
        env:
          DATABASE_ADAPTER: ${{ matrix.database }}
        run: bin/ci
```

## Debugging Tests

### When Tests Fail

**Run with backtrace:**
```bash
bin/rails test --backtrace
```

**Run with verbose output:**
```bash
bin/rails test --verbose
```

**Use debugger:**
```ruby
test "something" do
  binding.break  # Pauses execution
  assert true
end
```

**Check logs:**
```bash
tail -f log/test.log
```

**Inspect database:**
```bash
RAILS_ENV=test bin/rails dbconsole
```

## Common Testing Pitfalls

### Multi-Tenancy
❌ **DON'T:**
```ruby
Card.find(card.id)  # Might get wrong account's card
```

✅ **DO:**
```ruby
@account.cards.find(card.id)  # Properly scoped
```

### Time-Dependent Tests
❌ **DON'T:**
```ruby
assert_equal Time.now, @card.updated_at  # Flaky!
```

✅ **DO:**
```ruby
freeze_time do
  @card.touch
  assert_equal Time.current, @card.updated_at
end
```

### Asynchronous Behavior
❌ **DON'T:**
```ruby
click_on "Update"
assert_text "Updated"  # Might fail before Turbo completes
```

✅ **DO:**
```ruby
click_on "Update"
assert_selector ".card", text: "Updated", wait: 5
```

### Database State
❌ **DON'T:**
```ruby
test "counts" do
  assert_equal 5, Card.count  # Fragile, depends on fixtures
end
```

✅ **DO:**
```ruby
test "creates card" do
  assert_difference -> { Card.count }, 1 do
    create_card
  end
end
```

## Testing Checklist

When adding a new feature, ensure:
- [ ] Model validations tested
- [ ] Model associations tested
- [ ] Account scoping tested (multi-tenancy)
- [ ] Controller actions tested
- [ ] Authorization tested
- [ ] Event tracking tested
- [ ] Background jobs tested
- [ ] UI interactions tested (system tests)
- [ ] Edge cases tested (nil, empty, invalid)
- [ ] Error handling tested
- [ ] Integration with other features tested

## Resources

- **Rails Testing Guide**: https://guides.rubyonrails.org/testing.html
- **Minitest Documentation**: https://docs.seattlerb.org/minitest/
- **Capybara Cheat Sheet**: https://devhints.io/capybara
- **WebMock**: https://github.com/bblimke/webmock
- **Mocha**: https://github.com/freerange/mocha
