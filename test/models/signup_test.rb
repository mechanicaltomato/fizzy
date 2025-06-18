require "test_helper"

class SignupTest < ActiveSupport::TestCase
  setup do
    @signup = Signup.new(
      email_address: "brian@example.com",
      full_name: "Brian Wilson",
      company_name: "Beach Boys",
      password: SecureRandom.hex(16)
    )
  end

  test "#to_h allows persistence of the signup data" do
    actual = @signup.to_h
    expected = {
      email_address: @signup.email_address,
      full_name: @signup.full_name,
      company_name: @signup.company_name
    }
    assert_equal expected, actual
  end

  test "#process creates all the necessary objects for a new identity" do
    Account.any_instance.expects(:setup_basic_template).once

    assert @signup.process, @signup.errors.full_messages.to_sentence(words_connector: ". ")
    assert_empty @signup.errors

    assert @signup.signal_identity
    assert @signup.signal_identity.persisted?

    assert @signup.queenbee_account
    assert @signup.queenbee_account.id

    assert @signup.signal_account
    assert @signup.signal_account.persisted?
    assert_equal @signup.signal_identity, @signup.signal_account.owner.identity
    assert_equal @signup.company_name, @signup.signal_account.name

    assert @signup.account
    assert @signup.account.persisted?

    assert @signup.user
    assert @signup.user.persisted?
    assert_equal @signup.user.signal_user, @signup.signal_account.owner

    assert_includes ApplicationRecord.tenants, @signup.signal_account.subdomain
  end

  test "the new account is named with company name if present" do
    assert_equal @signup.company_name, @signup.send(:queenbee_account_name)
  end

  test "in beta, the new account is named distinctly" do
    Rails.stubs(:env).returns(stub(beta?: true))

    assert_equal "#{@signup.company_name} (Beta)", @signup.send(:queenbee_account_name)
  end

  test "#process creates all the necessary objects for an existing identity" do
    signal_identity = SignalId::Identity.find_by_email_address("david@37signals.com")

    @signup = Signup.new(
      signal_identity: signal_identity,
      company_name: "Team LeMans",
    )

    Account.any_instance.expects(:setup_basic_template).once

    assert @signup.process, @signup.errors.full_messages.to_sentence(words_connector: ". ")
    assert_empty @signup.errors

    assert @signup.signal_identity
    assert_equal signal_identity, @signup.signal_identity

    assert @signup.queenbee_account
    assert @signup.queenbee_account.id

    assert @signup.signal_account
    assert @signup.signal_account.persisted?
    assert_equal @signup.signal_identity, @signup.signal_account.owner.identity

    assert @signup.account
    assert @signup.account.persisted?

    assert @signup.user
    assert @signup.user.persisted?
    assert_equal @signup.user.signal_user, @signup.signal_account.owner

    assert_includes ApplicationRecord.tenants, @signup.signal_account.subdomain
  end

  test "#process does nothing if a validation error occurs creating identity" do
    @signup.password = ""

    assert_not @signup.process
    assert_not_empty @signup.errors[:password]

    assert_nil @signup.signal_identity
    assert_nil @signup.queenbee_account
    assert_nil @signup.account
    assert_nil @signup.user
  end

  test "#process does nothing if a validation error occurs creating the queenbee account" do
    Queenbee::Remote::Account.stubs(:create!).raises(RuntimeError, "Invalid account data")

    SignalId::Identity.any_instance.expects(:destroy).once

    assert_not @signup.process
    assert_not_empty @signup.errors[:base]

    assert_nil @signup.signal_identity
    assert_nil @signup.queenbee_account
    assert_nil @signup.account
    assert_nil @signup.user
  end

  test "#process does nothing if a validation error occurs creating the tenant" do
    ApplicationRecord.stubs(:create_tenant).raises(RuntimeError, "Tenant already exists")

    Queenbee::Remote::Account.any_instance.expects(:cancel).once
    SignalId::Identity.any_instance.expects(:destroy).once

    assert_not @signup.process
    assert_not_empty @signup.errors[:base]

    assert_nil @signup.signal_identity
    assert_nil @signup.queenbee_account
    assert_nil @signup.account
    assert_nil @signup.user
  end

  test "#process does nothing if a validation error occurs creating the account" do
    Account.stubs(:create_with_admin_user).raises(RuntimeError, "Account creation failed")

    ApplicationRecord.expects(:destroy_tenant).once
    Queenbee::Remote::Account.any_instance.expects(:cancel).once
    SignalId::Identity.any_instance.expects(:destroy).once

    assert_not @signup.process
    assert_not_empty @signup.errors[:base]

    assert_nil @signup.signal_identity
    assert_nil @signup.queenbee_account
    assert_nil @signup.account
    assert_nil @signup.user
  end
end
