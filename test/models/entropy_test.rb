require "test_helper"

class Entropy::Test < ActiveSupport::TestCase
  test "touch cards when entropy changes for collection container" do
    collection = collections(:writebook)
    config = collection.entropy || collection.create_entropy!(auto_postpone_period: 30.days)

    assert_enqueued_with(job: Card::TouchAllJob, args: [ collection ]) do
      config.update!(auto_postpone_period: 15.days)
    end
  end

  test "touch cards when entropy changes for account container" do
    account = Account.sole

    assert_enqueued_with(job: Card::TouchAllJob, args: [ account ]) do
      account.default_entropy.update!(auto_postpone_period: 45.days)
    end
  end
end
