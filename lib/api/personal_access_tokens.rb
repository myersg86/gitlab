# frozen_string_literal: true

module API
  class PersonalAccessTokens < Grape::API::Instance
    desc 'Get all Personal Access Tokens' do
      success Entities::PersonalAccessToken
    end
    params do
      optional :user_id, type: Integer, desc: 'User ID'
    end

    before do
      forbidden! unless current_user.present?
    end

    helpers do
      def finder_params(user)
        user.admin? ? { user: params[:user_id] } : { user: current_user }
      end
    end

    get :personal_access_tokens do
      tokens = PersonalAccessTokensFinder.new(finder_params(current_user)).execute
      tokens = tokens.select { |token| can? current_user, :read_token, token }

      present tokens, with: Entities::PersonalAccessToken
    end
  end
end
