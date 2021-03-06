# frozen_string_literal: true

module Api
  module V1
    class ResharesController < Api::V1::BaseController
      before_action except: %i[create] do
        require_access_token %w[public:read]
      end

      before_action only: %i[create] do
        require_access_token %w[public:modify]
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: I18n.t("api.endpoint_errors.posts.post_not_found"), status: :not_found
      end

      rescue_from Diaspora::NonPublic do
        render json: I18n.t("api.endpoint_errors.posts.post_not_found"), status: :not_found
      end

      def show
        reshares_query = reshare_service.find_for_post(params.require(:post_id))
        reshares_page = index_pager(reshares_query).response
        reshares_page[:data] = reshares_page[:data].map do |r|
          {
            guid:   r.guid,
            created_at: r.created_at,
            author: PersonPresenter.new(r.author).as_api_json
          }
        end
        render_paged_api_response reshares_page
      end

      def create
        reshare = reshare_service.create(params.require(:post_id))
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, RuntimeError
        render plain: I18n.t("reshares.create.error"), status: :unprocessable_entity
      else
        render json: PostPresenter.new(reshare, current_user).as_api_response
      end

      private

      def reshare_service
        @reshare_service ||= ReshareService.new(current_user)
      end
    end
  end
end
