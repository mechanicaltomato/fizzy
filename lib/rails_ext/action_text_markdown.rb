module ActionText
  class Markdown < Record
    mattr_accessor :html_renderer
    mattr_accessor :plain_renderer

    belongs_to :record, polymorphic: true, touch: true

    def to_html
      to_unsafe_html.html_safe
    end

    def to_unsafe_html
      (html_renderer.try(:call) || html_renderer).render(content)
    end

    def to_plain_text
      (plain_renderer.try(:call) || plain_renderer).render(content)
    end
  end
end

module ActionText::Markdown::Uploads
  extend ActiveSupport::Concern

  included do
    has_many_attached :uploads, dependent: :destroy
  end
end

ActiveSupport.on_load :active_storage_attachment do
  class ActionText::Markdown
    include ActionText::Markdown::Uploads
  end
end

ActiveSupport.run_load_hooks :action_text_markdown, ActionText::Markdown
