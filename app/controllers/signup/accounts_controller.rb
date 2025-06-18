class Signup::AccountsController < Signup::BaseController
  before_action :reset_signup_storage

  def new
    @signup = Signup.new
  end

  def create
    @signup = Signup.new(signup_params)

    if @signup.recognized?
      store_signup
      redirect_to Launchpad.authentication_url(purpose: "signup", login_hint: @signup.email_address, redirect_uri: signup_session_url), allow_other_host: true
    elsif @signup.process
      redirect_to_account(@signup.account)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def signup_params
      params.require(:signup).permit(*Signup::PERMITTED_KEYS)
    end

    def store_signup
      @signup.to_h.each { |key, value| signup_storage[key.to_s] = value }
    end
end
