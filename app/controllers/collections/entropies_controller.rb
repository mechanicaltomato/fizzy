class Collections::EntropiesController < ApplicationController
  include CollectionScoped

  def update
    @collection.entropy.update!(entropy_params)

    render turbo_stream: [
        turbo_stream.replace([ @collection, :entropy ], partial: "collections/edit/auto_close", locals: { collection: @collection }),
        turbo_stream_flash(notice: "Saved")
      ]
  end

  private
    def entropy_params
      params.expect(collection: [ :auto_postpone_period ])
    end
end
