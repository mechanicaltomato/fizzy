class Ai::Tokenizer
  attr_reader :text, :max_input_tokens

  class << self
    def truncate(text, max_input_tokens: 8196)
      new(text, max_input_tokens:).truncated
    end
  end

  def initialize(text, max_input_tokens: 8196)
    @text = text
    @max_input_tokens = max_input_tokens
  end

  def truncated
    # Truncating the tokens might split a unicode character so if we get an error
    # we'll try removing an extra token
    # The encode/decode round trip seems to add a token, so we start with max_input_tokens - 1
    (1..4).each do |i|
      tokens = tokenizer.encode(text)[0..(max_input_tokens - 20 - i)]
      return tokenizer.decode(tokens)
    rescue Tiktoken::UnicodeError
      raise if i == 4
    end
  end

  private
    def tokenizer
      @tokenizer ||= Tiktoken.encoding_for_model("text-embedding-3-small")
    end
end
