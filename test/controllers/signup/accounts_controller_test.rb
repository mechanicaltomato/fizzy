require "test_helper"

class Signup::AccountsControllerTest < ActionDispatch::IntegrationTest
  test "new at a tenanted domain" do
    get new_signup_account_url

    assert_redirected_to root_url
  end

  test "new at an untenanted domain" do
    integration_session.host = "example.com" # no subdomain

    get new_signup_account_url

    assert_response :success
  end

  test "create with invalid params" do
    integration_session.host = "example.com" # no subdomain

    post signup_accounts_url, params: { signup: { full_name: "Jim", email_address: "jim@example.com", password: "", company_name: "" } }

    assert_response :unprocessable_entity
    assert_select "div.alert--error", text: /you need to choose a password/i
  end

  test "create for a new " do
    integration_session.host = "example.com" # no subdomain

    assert_difference -> { SignalId::Identity.count }, +1 do
      assert_difference -> { SignalId::Account.count }, +1 do
        post signup_accounts_url, params: { signup: { full_name: "Jim", email_address: "jim@example.com", password: SecureRandom.hex(12), company_name: "signup-accounts-controller-test-1" } }
      end
    end

    signal_account = SignalId::Account.last
    assert_redirected_to(/#{signal_account.login_url}/)
  end

  test "create for an existing identity" do
    integration_session.host = "example.com" # no subdomain

    identity = signal_identities(:david)

    post signup_accounts_url, params: { signup: { email_address: identity.email_address, company_name: "signup-accounts-controller-test-2" } }
    assert_authentication_requested_for identity

    assert_no_difference -> { SignalId::Identity.count } do
      assert_difference -> { SignalId::Account.count } do
        authenticate_via_launchpad_as(identity)
        assert_redirected_to_account
        assert_nil session[:signup]
      end
    end

    signal_account = SignalId::Account.last
    ApplicationRecord.with_tenant(signal_account.subdomain) do
      assert_equal Account.last, signal_account.peer
    end
  end

  def assert_authentication_requested_for(identity)
    assert_response :redirect
    assert_match(/#{Regexp.escape(Launchpad.url("/authenticate", login_hint: identity.email_address))}.*&purpose=signup/, redirect_to_url)
  end

  def authenticate_via_launchpad_as(identity)
    get signup_session_url, params: { sig: identity.perishable_signature }
    assert_equal identity.id, session[:signup]["identity_id"]
    assert_redirected_to new_signup_completion_url
    post signup_completions_url
  end

  def assert_redirected_to_account(signal_account = SignalId::Account.last)
    assert_response :redirect
    assert_match(/#{Regexp.escape(signal_account.url("/session/launchpad"))}.*&sig=/, redirect_to_url)
  end
end
