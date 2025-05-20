class Command::Result::Redirection
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def as_json
    { redirect_to: url }
  end
end
