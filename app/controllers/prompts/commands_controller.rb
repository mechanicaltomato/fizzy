class Prompts::CommandsController < ApplicationController
  def index
    @commands = [
      [ "/add_card", "Create a new card", "/add_card " ],
      [ "/assign", "Assign cards to users", "/assign @" ],
      [ "/clear", "Clear current filters", "/clear" ],
      [ "/close", "Close cards with a reason", "/close " ],
      [ "/consider", "Reconsider cards", "/consider" ],
      [ "/do", "Move cards to doing", "/do" ],
      [ "/reconsider", "Move cards to reconsidering", "/reconsider" ],
      [ "/search", "Search cards and comments", "/search " ],
      [ "/tag", "Tag selected cards", "/tag #" ],
      [ "/stage", "Set cards to a workflow stage", "/stage " ]
    ]

    if stale? etag: @commands
      render layout: false
    end
  end
end
