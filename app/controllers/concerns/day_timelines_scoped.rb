module DayTimelinesScoped
  extend ActiveSupport::Concern

  included do
    include FilterScoped

    before_action :restore_collections_filter, :set_day_timeline
    after_action :save_collections_filter
  end

  private
    def restore_collections_filter
      clear_collections_filter if clear_collections_filter?
      @filter.collection_ids = cookies[:collection_filter].split(",") if cookies[:collection_filter].present?
    end

    def clear_collections_filter?
      params[:clear_filter]
    end

    def clear_collections_filter
      cookies.delete(:collection_filter)
    end

    def set_day_timeline
      @day_timeline = Current.user.timeline_for(day, filter: @filter)
    end

    def day
      if params[:day].present?
        Time.zone.parse(params[:day])
      else
        Time.current
      end
    rescue ArgumentError
      head :not_found
    end

    def save_collections_filter
      if params[:collection_ids].present?
        cookies[:collection_filter] = params[:collection_ids].join(",")
      end
    end
end
