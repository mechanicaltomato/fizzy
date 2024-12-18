require "rouge/plugins/redcarpet"

class MarkdownRenderer < HouseMd::Renderer
  class Generator < HouseMd::Generator::Html
    include Rouge::Plugins::Redcarpet

    def initialize
      @id_counts = Hash.new 0
    end

    def header(text, header_level)
      unique_id(text).then do |id|
        <<~HTML.chomp
          <h#{header_level} id="#{id}">
            #{text} <a href="##{id}" class="heading__link" aria-hidden="true">#</a>
          </h#{header_level}>
        HTML
      end
    end

    def image(url, alt_text)
      <<~HTML.chomp
        <a href="#{url}" data-action="lightbox#open:prevent" data-lightbox-target="image" data-lightbox-url-value="#{url}?disposition=attachment">
          <img src="#{url}" alt="#{alt_text}">
        </a>
      HTML
    end

    def code_block(code, language)
      block_code(code, language) # call Rouge Redcarpet plugin
    end

    private
      attr_reader :id_counts

      def unique_id(text)
        text.parameterize.then do |base_id|
          id_counts[base_id] += 1
          id_counts[base_id] > 1 ? "#{base_id}-#{id_counts[base_id]}" : base_id
        end
      end
  end

  def initialize
    @generator = Generator.new
  end
end
