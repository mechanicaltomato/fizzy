module Account::Entropic
  extend ActiveSupport::Concern

  included do
    has_one :default_entropy, class_name: "Entropy", as: :container, dependent: :destroy

    before_save :set_default_entropy
  end

  private
    DEFAULT_ENTROPY_PERIOD = 30.days

    def set_default_entropy
      self.default_entropy ||= build_default_entropy \
        auto_postpone_period: DEFAULT_ENTROPY_PERIOD
    end
end
