class Signup::CompletionsController < Signup::BaseController
  before_action :set_authenticated_identity, only: :create

  def new
  end

  def create
    @signup = Signup.new(signup_params)
    @signup.signal_identity = authenticated_identity

    if @signup.process
      reset_signup_storage
      redirect_to_account(@signup.account)
    else
      render plain: "Could not complete signup. This is probably a bug.", status: :unprocessable_entity, layout: false
    end
  end

  private
    def signup_params
      signup_storage.slice(*Signup::PERMITTED_KEYS.map(&:to_s))
    end
end
