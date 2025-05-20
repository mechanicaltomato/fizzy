require "test_helper"

class Command::CompositeTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  test "execute commands in order and return an array with the results" do
    command = Command::Composite.new(commands: [ build_command(result: "1"), build_command(result: "2") ])
    assert_equal [ "1", "2" ], command.execute
  end

  test "undo the commands in reverse order" do
    command = Command::Composite.new(commands: [ build_command(result: "1", undoable: true), build_command(result: "2", undoable: true) ])
    assert_equal [ "2", "1" ], command.undo
  end

  test "undoable if some of the commands is" do
    assert_not Command::Composite.new(commands: [ build_command(undoable: false), build_command(undoable: false) ]).undoable?
    assert Command::Composite.new(commands: [ build_command(undoable: true), build_command(undoable: false) ]).undoable?
  end

  test "needs confirmation if some of the command does" do
    assert_not Command::Composite.new(commands: [ build_command(needs_confirmation: false), build_command(needs_confirmation: false) ]).needs_confirmation?
    assert Command::Composite.new(commands: [ build_command(needs_confirmation: true), build_command(needs_confirmation: false) ]).needs_confirmation?
  end

  private
    def build_command(...)
      TestCommand.new(...)
    end

    class TestCommand < Command
      attribute :result
      attribute :undoable
      attribute :needs_confirmation

      def execute
        result
      end

      def undo
        result
      end

      def undoable?
        undoable
      end

      def needs_confirmation?
        needs_confirmation
      end
    end
end
