# Extension Points for Fizzy

This guide identifies specific locations and patterns for extending Fizzy with custom features.

## Table of Contents

1. [AI/LLM Features](#aillm-features)
2. [Custom Card Fields](#custom-card-fields)
3. [External Integrations](#external-integrations)
4. [UI Customizations](#ui-customizations)
5. [Automation & Workflows](#automation--workflows)
6. [Analytics & Reporting](#analytics--reporting)
7. [API Endpoints](#api-endpoints)

---

## AI/LLM Features

### 1. Card Summarization

**Location**: `app/controllers/cards/ai_summaries_controller.rb` (create new)

```ruby
class Cards::AiSummariesController < ApplicationController
  before_action :set_card

  def create
    AiSummaryJob.perform_later(@card)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "card_#{@card.id}_summary",
          partial: "cards/ai_summaries/generating"
        )
      end
    end
  end

  private
    def set_card
      @card = Current.account.cards.find(params[:card_id])
    end
end
```

**Job**: `app/jobs/ai_summary_job.rb`
```ruby
class AiSummaryJob < ApplicationJob
  def perform(card)
    # Use card.to_prompt to get formatted content
    prompt = card.to_prompt

    # Call your LLM API
    summary = call_llm_api(prompt)

    # Store result
    card.update(ai_summary: summary)

    # Broadcast update via Turbo Stream
    card.broadcast_replace_to(
      card,
      target: "card_#{card.id}_summary",
      partial: "cards/ai_summaries/show",
      locals: { card: card }
    )
  end

  private
    def call_llm_api(prompt)
      # Implement your LLM API call here
      # OpenAI, Claude, etc.
    end
end
```

**Migration**:
```bash
bin/rails generate migration AddAiSummaryToCards ai_summary:text
```

```ruby
class AddAiSummaryToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :ai_summary, :text
    add_index :cards, [:account_id, :updated_at]
  end
end
```

**Route**:
```ruby
# config/routes.rb
resources :cards do
  scope module: :cards do
    resource :ai_summary, only: [:create]
  end
end
```

**View**: `app/views/cards/show.html.erb`
```erb
<div id="card_<%= @card.id %>_summary">
  <% if @card.ai_summary? %>
    <%= render "cards/ai_summaries/show", card: @card %>
  <% else %>
    <%= button_to "Generate AI Summary",
                  card_ai_summary_path(@card),
                  method: :post,
                  data: { turbo_frame: "_top" } %>
  <% end %>
</div>
```

### 2. Smart Tagging

**Service**: `app/models/card/ai_tagger.rb`
```ruby
class Card::AiTagger
  def initialize(card)
    @card = card
  end

  def suggest_tags
    prompt = build_prompt
    response = call_llm_api(prompt)
    parse_tags(response)
  end

  private
    def build_prompt
      <<~PROMPT
        Based on this card, suggest relevant tags:

        #{@card.to_prompt}

        Return only comma-separated tag names.
      PROMPT
    end

    def call_llm_api(prompt)
      # Your LLM API call
    end

    def parse_tags(response)
      response.split(",").map(&:strip)
    end
end
```

**Usage in controller**:
```ruby
class Cards::AiTaggingsController < ApplicationController
  def create
    @card = Current.account.cards.find(params[:card_id])
    suggested_tags = Card::AiTagger.new(@card).suggest_tags

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "card_#{@card.id}_tag_suggestions",
          partial: "cards/ai_taggings/suggestions",
          locals: { card: @card, suggested_tags: suggested_tags }
        )
      end
    end
  end
end
```

### 3. Task Breakdown (Generate Steps)

**Extend**: `app/models/card.rb`
```ruby
# In Card model
def ai_generate_steps
  prompt = <<~PROMPT
    Break down this task into concrete steps:

    #{to_prompt}

    Return numbered steps, one per line.
  PROMPT

  response = AiService.call(prompt)
  steps_text = response.split("\n").map { |line| line.gsub(/^\d+\.\s*/, "") }

  transaction do
    steps_text.each_with_index do |step_text, index|
      steps.create!(
        description: step_text,
        position: index + 1,
        creator: Current.user
      )
    end
  end

  track_event "ai_steps_generated", particulars: { count: steps_text.size }
end
```

---

## Custom Card Fields

### Adding a Custom Field (Example: Priority Score)

**1. Generate migration:**
```bash
bin/rails generate migration AddPriorityScoreToCards priority_score:integer
```

**2. Edit migration:**
```ruby
class AddPriorityScoreToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :priority_score, :integer, default: 0
    add_index :cards, [:account_id, :priority_score]
  end
end
```

**3. Update model:**
```ruby
# app/models/card.rb
class Card < ApplicationRecord
  validates :priority_score,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    allow_nil: true

  scope :high_priority, -> { where("priority_score > ?", 7) }
  scope :by_priority, -> { order(priority_score: :desc, created_at: :desc) }

  # Track changes
  after_update :track_priority_change, if: :saved_change_to_priority_score?

  private
    def track_priority_change
      track_event "priority_changed",
        particulars: {
          old_score: priority_score_before_last_save,
          new_score: priority_score
        }
    end
end
```

**4. Update controller:**
```ruby
# app/controllers/cards_controller.rb
def card_params
  params.require(:card).permit(
    :title,
    :description,
    :priority_score,  # Add this
    # ... other fields
  )
end
```

**5. Add form field:**
```erb
<!-- app/views/cards/_form.html.erb -->
<%= form.number_field :priority_score,
                      min: 0,
                      max: 10,
                      class: "form-control" %>
```

**6. Display in view:**
```erb
<!-- app/views/cards/show.html.erb -->
<div class="card-priority">
  Priority Score: <%= @card.priority_score || "Not set" %>
</div>
```

**7. Add tests:**
```ruby
# test/models/card_test.rb
test "should validate priority score is positive" do
  @card.priority_score = -1
  assert_not @card.valid?
end

test "should track priority change event" do
  assert_difference -> { Event.count }, 1 do
    @card.update(priority_score: 8)
  end
end
```

---

## External Integrations

### 1. GitHub Issues Sync

**Service**: `app/models/integrations/github_syncer.rb`
```ruby
class Integrations::GithubSyncer
  def initialize(account)
    @account = account
    @client = Octokit::Client.new(access_token: @account.github_token)
  end

  def sync_issues(repo_name)
    issues = @client.issues(repo_name, state: "open")

    issues.each do |issue|
      sync_issue(issue)
    end
  end

  private
    def sync_issue(github_issue)
      card = @account.cards.find_or_initialize_by(
        github_issue_id: github_issue.id
      )

      card.assign_attributes(
        title: github_issue.title,
        description: github_issue.body,
        github_url: github_issue.html_url
      )

      if card.new_record?
        card.creator = @account.system_user
        card.save!
        card.track_event "github_issue_imported"
      elsif card.changed?
        card.save!
        card.track_event "github_issue_synced"
      end
    end
end
```

**Migration**:
```bash
bin/rails generate migration AddGithubFieldsToCards github_issue_id:bigint github_url:string
bin/rails generate migration AddGithubTokenToAccounts github_token:string
```

**Job**:
```ruby
# app/jobs/github_sync_job.rb
class GithubSyncJob < ApplicationJob
  def perform(account, repo_name)
    Integrations::GithubSyncer.new(account).sync_issues(repo_name)
  end
end
```

**Recurring sync** (add to `config/recurring.yml`):
```yaml
sync_github_issues:
  schedule: every hour
  class: GithubSyncJob
  args: [<%= Account.find_by(name: "My Account").id %>, "owner/repo"]
```

### 2. Slack Bot Commands

**Controller**: `app/controllers/api/slack_controller.rb`
```ruby
class Api::SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_slack_signature

  def commands
    case params[:command]
    when "/fizzy-create"
      create_card
    when "/fizzy-list"
      list_cards
    else
      render json: { text: "Unknown command" }
    end
  end

  private
    def create_card
      # Parse: /fizzy-create [board] Title of card
      board_name, title = parse_create_command(params[:text])
      board = current_account.boards.find_by(name: board_name)

      card = board.cards.create!(
        title: title,
        creator: slack_user
      )

      render json: {
        text: "Created card: #{card.title}",
        response_type: "in_channel"
      }
    end

    def list_cards
      cards = current_account.cards.open.limit(10)

      render json: {
        text: "Recent cards:\n" + cards.map { |c| "• #{c.title}" }.join("\n"),
        response_type: "ephemeral"
      }
    end

    def verify_slack_signature
      # Implement Slack signature verification
      # https://api.slack.com/authentication/verifying-requests-from-slack
    end

    def current_account
      # Look up account by Slack team_id or workspace
      Account.find_by(slack_team_id: params[:team_id])
    end

    def slack_user
      # Find or create user based on Slack user_id
      current_account.users.find_or_create_by(slack_user_id: params[:user_id])
    end
end
```

**Route**:
```ruby
# config/routes.rb
namespace :api do
  post "slack/commands", to: "slack#commands"
end
```

### 3. Email to Card

**Mailer**: `app/mailboxes/cards_mailbox.rb`
```ruby
class CardsMailbox < ApplicationMailbox
  # Route emails like: create-card-123@fizzy.example.com
  MATCHER = /create-card-(\d+)@/i

  before_processing :set_account

  def process
    card = @account.cards.create!(
      title: mail.subject,
      description: mail.body.decoded,
      creator: find_or_create_user_from_email
    )

    card.track_event "card_created_via_email"
  end

  private
    def set_account
      account_id = mail.to.first.match(MATCHER)[1]
      @account = Account.find_by(external_account_id: account_id)
    end

    def find_or_create_user_from_email
      identity = Identity.find_by(email: mail.from.first)
      identity&.users&.find_by(account: @account) || @account.system_user
    end
end
```

**Route** (in `config/application.rb`):
```ruby
config.action_mailbox.ingress = :postmark  # or :sendgrid, :mailgun, etc.
```

---

## UI Customizations

### 1. Custom Card Display Component

**Stimulus Controller**: `app/javascript/controllers/custom_card_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "actions"]
  static values = {
    cardId: String,
    expanded: Boolean
  }

  connect() {
    this.updateDisplay()
  }

  toggle(event) {
    this.expandedValue = !this.expandedValue
    this.updateDisplay()
  }

  updateDisplay() {
    if (this.expandedValue) {
      this.contentTarget.classList.add("expanded")
      this.actionsTarget.classList.remove("hidden")
    } else {
      this.contentTarget.classList.remove("expanded")
      this.actionsTarget.classList.add("hidden")
    }
  }

  async quickEdit(event) {
    const response = await fetch(`/cards/${this.cardIdValue}/edit`, {
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    })

    const html = await response.text()
    Turbo.renderStreamMessage(html)
  }
}
```

**Usage**:
```erb
<div data-controller="custom-card"
     data-custom-card-card-id-value="<%= card.id %>"
     data-custom-card-expanded-value="false">
  <div data-custom-card-target="content">
    <%= card.title %>
  </div>
  <div data-custom-card-target="actions" class="hidden">
    <button data-action="click->custom-card#quickEdit">Edit</button>
  </div>
  <button data-action="click->custom-card#toggle">Toggle</button>
</div>
```

### 2. Custom Board Layout

**CSS**: `app/assets/stylesheets/custom_board_layout.css`
```css
/* Add custom board layout */
.board--custom-layout {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.board--custom-layout .column {
  background: var(--column-bg);
  border-radius: 8px;
  padding: 1rem;
}

/* Card hover effects */
.card--custom:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  transition: all 0.2s ease;
}
```

**View**: Customize `app/views/boards/show.html.erb`
```erb
<div class="board board--custom-layout" data-controller="board">
  <%= render partial: "columns/column",
             collection: @board.columns,
             locals: { board: @board } %>
</div>
```

### 3. Custom Keyboard Shortcuts

**Stimulus Controller**: `app/javascript/controllers/custom_hotkeys_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundHandler = this.handleKeypress.bind(this)
    document.addEventListener("keydown", this.boundHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandler)
  }

  handleKeypress(event) {
    // Don't trigger if typing in input/textarea
    if (event.target.matches("input, textarea")) return

    // Cmd/Ctrl + K: Quick search
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.openQuickSearch()
    }

    // Cmd/Ctrl + N: New card
    if ((event.metaKey || event.ctrlKey) && event.key === "n") {
      event.preventDefault()
      this.openNewCard()
    }

    // G then B: Go to boards
    if (this.lastKey === "g" && event.key === "b") {
      this.navigateTo("/boards")
    }

    this.lastKey = event.key
    setTimeout(() => { this.lastKey = null }, 1000)
  }

  openQuickSearch() {
    const searchInput = document.querySelector("#quick-search")
    searchInput?.focus()
  }

  openNewCard() {
    Turbo.visit("/cards/new")
  }

  navigateTo(path) {
    Turbo.visit(path)
  }
}
```

**Usage**: Add to `app/views/layouts/application.html.erb`
```erb
<body data-controller="custom-hotkeys">
  <%= yield %>
</body>
```

---

## Automation & Workflows

### 1. Auto-Assignment Rules

**Service**: `app/models/board/auto_assigner.rb`
```ruby
class Board::AutoAssigner
  def initialize(board)
    @board = board
  end

  def assign_card(card)
    rule = find_matching_rule(card)
    return unless rule

    assignees = rule.assignees
    card.assign!(assignees)

    card.track_event "auto_assigned",
      particulars: { rule_id: rule.id, assignees: assignees.map(&:name) }
  end

  private
    def find_matching_rule(card)
      @board.auto_assignment_rules.find do |rule|
        rule.matches?(card)
      end
    end
end
```

**Model**: `app/models/auto_assignment_rule.rb`
```ruby
class AutoAssignmentRule < ApplicationRecord
  belongs_to :board
  has_many :rule_assignees
  has_many :assignees, through: :rule_assignees, source: :user

  # JSON column for conditions
  # { "tag_includes": ["urgent"], "title_matches": "bug" }
  def matches?(card)
    return false unless conditions.present?

    conditions.all? do |condition_type, condition_value|
      case condition_type
      when "tag_includes"
        card.tags.pluck(:name).any? { |tag| condition_value.include?(tag) }
      when "title_matches"
        card.title.match?(/#{condition_value}/i)
      when "column"
        card.column&.name == condition_value
      else
        false
      end
    end
  end
end
```

**Hook**: Add to `app/models/card.rb`
```ruby
# In Card model
after_create :auto_assign, if: :board_has_auto_assignment?

private
  def auto_assign
    Board::AutoAssigner.new(board).assign_card(self)
  end

  def board_has_auto_assignment?
    board.auto_assignment_rules.any?
  end
```

### 2. Card Templates

**Model**: `app/models/card_template.rb`
```ruby
class CardTemplate < ApplicationRecord
  belongs_to :account
  belongs_to :board, optional: true

  has_rich_text :description_template

  def instantiate(attributes = {})
    account.cards.new(
      title: attributes[:title] || title_template,
      description: description_template.body,
      board: attributes[:board] || board
    ).tap do |card|
      # Copy steps if any
      steps_data.each do |step_text|
        card.steps.build(description: step_text)
      end
    end
  end
end
```

**Controller**: `app/controllers/card_templates_controller.rb`
```ruby
class CardTemplatesController < ApplicationController
  def apply
    @template = CardTemplate.find(params[:id])
    @card = @template.instantiate(card_params)

    if @card.save
      redirect_to @card, notice: "Card created from template"
    else
      render :new
    end
  end
end
```

---

## Analytics & Reporting

### 1. Card Velocity Dashboard

**Model**: `app/models/analytics/card_velocity.rb`
```ruby
class Analytics::CardVelocity
  def initialize(board, time_range: 30.days)
    @board = board
    @time_range = time_range
  end

  def calculate
    {
      cards_created: cards_created_count,
      cards_closed: cards_closed_count,
      average_time_to_close: average_time_to_close,
      cards_by_column: cards_by_column_count
    }
  end

  private
    def cards_created_count
      @board.cards.where(created_at: @time_range.ago..Time.current).count
    end

    def cards_closed_count
      @board.cards.closed.where(closed_at: @time_range.ago..Time.current).count
    end

    def average_time_to_close
      closed_cards = @board.cards.closed
        .where(closed_at: @time_range.ago..Time.current)

      return 0 if closed_cards.empty?

      total_seconds = closed_cards.sum do |card|
        (card.closed_at - card.created_at).to_i
      end

      (total_seconds / closed_cards.count.to_f / 1.day).round(1)
    end

    def cards_by_column_count
      @board.columns.map do |column|
        [column.name, column.cards.count]
      end.to_h
    end
end
```

**Controller**: `app/controllers/boards/analytics_controller.rb`
```ruby
class Boards::AnalyticsController < ApplicationController
  def show
    @board = Board.find(params[:board_id])
    @velocity = Analytics::CardVelocity.new(@board).calculate
    @trend = Analytics::CardTrend.new(@board).weekly_data
  end
end
```

**View**: `app/views/boards/analytics/show.html.erb`
```erb
<div class="analytics-dashboard">
  <h2>Board Analytics</h2>

  <div class="metrics">
    <div class="metric">
      <h3>Cards Created</h3>
      <p><%= @velocity[:cards_created] %></p>
    </div>

    <div class="metric">
      <h3>Cards Closed</h3>
      <p><%= @velocity[:cards_closed] %></p>
    </div>

    <div class="metric">
      <h3>Avg Time to Close</h3>
      <p><%= @velocity[:average_time_to_close] %> days</p>
    </div>
  </div>

  <div class="charts">
    <canvas data-controller="chart"
            data-chart-type-value="line"
            data-chart-data-value="<%= @trend.to_json %>">
    </canvas>
  </div>
</div>
```

---

## API Endpoints

### RESTful API for Cards

**Controller**: `app/controllers/api/v1/cards_controller.rb`
```ruby
module Api
  module V1
    class CardsController < ApiController
      def index
        @cards = Current.account.cards.includes(:assignees, :tags)

        render json: @cards, each_serializer: CardSerializer
      end

      def show
        @card = Current.account.cards.find(params[:id])

        render json: @card, serializer: CardSerializer
      end

      def create
        @card = Current.account.cards.build(card_params)
        @card.creator = current_api_user

        if @card.save
          render json: @card, serializer: CardSerializer, status: :created
        else
          render json: { errors: @card.errors }, status: :unprocessable_entity
        end
      end

      def update
        @card = Current.account.cards.find(params[:id])

        if @card.update(card_params)
          render json: @card, serializer: CardSerializer
        else
          render json: { errors: @card.errors }, status: :unprocessable_entity
        end
      end

      private
        def card_params
          params.require(:card).permit(:title, :description, :board_id)
        end
    end
  end
end
```

**Base API Controller**: `app/controllers/api/api_controller.rb`
```ruby
class Api::ApiController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_token
  before_action :set_account_context

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private
    def authenticate_api_token
      authenticate_or_request_with_http_token do |token, options|
        @api_token = ApiToken.find_by(token: token)
        @api_token&.active?
      end
    end

    def set_account_context
      Current.account = @api_token.account
      Current.user = @api_token.user
    end

    def current_api_user
      @api_token.user
    end

    def not_found
      render json: { error: "Not found" }, status: :not_found
    end
end
```

**Serializer**: `app/serializers/card_serializer.rb`
```ruby
class CardSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :state, :created_at, :updated_at

  has_many :assignees
  has_many :tags
  belongs_to :board
  belongs_to :creator

  def description
    object.description.to_plain_text
  end
end
```

**API Token Model**: `app/models/api_token.rb`
```ruby
class ApiToken < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_secure_token :token

  scope :active, -> { where(revoked_at: nil) }

  def active?
    revoked_at.nil?
  end

  def revoke!
    update(revoked_at: Time.current)
  end
end
```

**Route**:
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :cards
    resources :boards, only: [:index, :show]
  end
end
```

---

## Best Practices for Extensions

### 1. Always Track Events
```ruby
# When creating significant features
card.track_event "custom_feature_used",
  particulars: { feature_data: value }
```

### 2. Maintain Account Scoping
```ruby
# Always scope to current account
Current.account.cards.find(id)

# Never use global queries
Card.find(id)  # ❌ Wrong!
```

### 3. Use Background Jobs for Slow Operations
```ruby
# For API calls, AI processing, etc.
MyFeatureJob.perform_later(card)
```

### 4. Broadcast Turbo Streams for UI Updates
```ruby
# After changes
card.broadcast_replace_to card
```

### 5. Write Tests
```ruby
# Always add tests for new features
test "custom feature works" do
  # Your test
end
```

---

## Need Help?

See also:
- `AI_DEVELOPMENT.md` - Development guidelines
- `SETUP.md` - Local setup instructions
- `TESTING.md` - Testing strategies
- `STYLE.md` - Code style guidelines
