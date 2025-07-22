require "test_helper"

class Admin::PromptSandboxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "show renders the form with default prompt" do
    get admin_prompt_sandbox_path

    assert_response :success
    assert_select "form[action=?]", admin_prompt_sandbox_path
    assert_select "textarea[name=?]", "prompt"
    assert_select "input[type=submit]"
  end

  test "create processes prompt and renders show with summary" do
    test_prompt = "Test prompt for summarization"

    post admin_prompt_sandbox_path, params: { prompt: test_prompt }

    assert_response :success
    assert_select "form[action=?]", admin_prompt_sandbox_path
    assert_select "textarea[name=?]", "prompt"
    assert_select "input[type=submit]"
    # The summary should be rendered outside the form
    assert_match /summary/, response.body.downcase
  end
end
