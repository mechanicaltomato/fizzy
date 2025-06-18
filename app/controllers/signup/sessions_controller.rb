class Signup::SessionsController < Signup::BaseController
  def create
    if self.authenticated_identity = SignalId::Identity.authenticate(params.permit(:sig))
      redirect_to new_signup_completion_url
    else
      render plain: "Authentication failed. This is probably a bug.", status: :unauthorized
    end
  end
end
