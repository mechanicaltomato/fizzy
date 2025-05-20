require "test_helper"

class Command::GoToCardTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  include VcrTestHelper

  setup do
    @card = cards(:logo)
  end

  test "redirect to the card perma" do
    result = execute_command "#{@card.id}"

    assert_equal @card, result.url
  end

  test "result in a regular search if the card does not exist" do
    command = parse_command "123"

    visit_command = command.commands.first
    assert visit_command.valid?

    result = visit_command.execute
    assert_equal cards_path(terms: [ "123" ]), result.url
  end
end
