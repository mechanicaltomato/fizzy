ActiveSupport.on_load :action_text_markdown do
  require "markdown_renderer"
  ActionText::Markdown.html_renderer = -> { MarkdownRenderer.new }
end
