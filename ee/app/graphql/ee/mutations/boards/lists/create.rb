module EE
  module Mutations
    module Boards
      module Lists
        module Create
          extend ActiveSupport::Concern

          prepended do
            argument :milestone_id, GraphQL::ID_TYPE,
                     required: false,
                     description: 'ID of an existing milestone'
            argument :assignee_id, GraphQL::ID_TYPE,
                     required: false,
                     description: 'ID of an assignee'

            def authorize_list_type_resource!(board, params)
              if params[:label_id] && !available_labels_for(board.resource_parent).exists?(params[:label_id])
                raise Gitlab::Graphql::Errors::ArgumentError, 'Label not found!'
              end

              if params[:milestone_id]
                milestones = ::Boards::MilestonesFinder.new(board, current_user).execute

                unless milestones.find_by(id: params[:milestone_id])
                  raise Gitlab::Graphql::Errors::ArgumentError, 'Milestone not found!'
                end
              end

              if params[:assignee_id]
                users = ::Boards::UsersFinder.new(board, current_user).execute

                unless users.find_by(user_id: params[:assignee_id])
                  raise Gitlab::Graphql::Errors::ArgumentError, 'User not found!'
                end
              end
            end
          end
        end
      end
    end
  end
end
