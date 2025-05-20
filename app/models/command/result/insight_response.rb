class Command::Result::InsightResponse
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def as_json
    { message: content }
  end
end
