class Account::EntropiesController < ApplicationController
  def update
    Entropy.default.update!(entropy_params)
    redirect_to account_settings_path, notice: "Account updated"
  end

  private
    def entropy_params
      params.expect(entropy: [ :auto_postpone_period ])
    end
end
