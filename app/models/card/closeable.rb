module Card::Closeable
  extend ActiveSupport::Concern

  AUTO_CLOSE_OPTIONS = [
    [ "30 days", 30.days ],
    [ "60 days", 60.days ],
    [ "90 days", 90.days ],
    [ "6 months", 180.days ],
    [ "1 year", 365.days ],
    [ "Never", nil ]
  ].freeze

  AUTO_CLOSE_AFTER = 30.days

  included do
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }

    scope :recently_closed_first, -> { closed.order("closures.created_at": :desc) }
    scope :due_to_be_closed, -> { considering.where(last_active_at: ..AUTO_CLOSE_AFTER.ago) }
  end

  class_methods do
    def auto_close_all_due
      due_to_be_closed.find_each do |card|
        card.close(user: User.system, reason: "Closed")
      end
    end
  end

  def auto_close_at
    last_active_at + AUTO_CLOSE_AFTER if last_active_at
  end

  def closed?
    closure.present?
  end

  def open?
    !closed?
  end

  def closed_by
    closure&.user
  end

  def closed_at
    closure&.created_at
  end

  def close(user: Current.user, reason: Closure::Reason::FALLBACK_LABEL)
    unless closed?
      transaction do
        create_closure! user: user, reason: reason
        track_event :closed, creator: user
      end
    end
  end

  def reopen
    closure&.destroy
  end
end
