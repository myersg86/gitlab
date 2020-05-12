# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Create < Base
        graphql_name 'CreateBoardList'

        # params :list_creation_params do
        #   optional :label_id, type: Integer, desc: 'The ID of an existing label'
        #   optional :milestone_id, type: Integer, desc: 'The ID of an existing milestone'
        #   optional :assignee_id, type: Integer, desc: 'The ID of an assignee'
        #   exactly_one_of :label_id, :milestone_id, :assignee_id
        # end
        argument :backlog, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 default_value: false,
                 description: 'Should a backlog list be created'

        argument :label_id, GraphQL::ID_TYPE,
                 required: false,
                 description: 'ID of an existing label'

        def ready?(**args)
          if args.values_at(:backlog, :label_id).compact.blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
                  'backlog or labelId argument is required'
          end

          super
        end

        def resolve(**args)
          board  = authorized_find!(id: args[:board_id])
          params = create_list_params(board, args)
          list   = create_list(board, params)

          {
            list: list.valid? ? list : nil,
            errors: errors_on_object(list)
          }
        end

        private

        def create_list_params(board, args)
          params            = args.slice(:backlog, :label_id)
          params[:label_id] = GitlabSchema.parse_gid(params[:label_id], expected_type: ::Label).model_id if params[:label_id]

          authorize_list_type_resource!(board, params)

          params
        end

        # Overridden in EE
        def authorize_list_type_resource!(board, params)
          if params[:label_id] && !available_labels_for(board.resource_parent).exists?(params[:label_id])
            raise Gitlab::Graphql::Errors::ArgumentError, 'Label not found!'
          end
        end

        def available_labels_for(label_parent, include_ancestor_groups: true)
          search_params = { include_ancestor_groups: include_ancestor_groups }

          if label_parent.is_a?(Project)
            search_params[:project_id] = label_parent.id
          else
            search_params.merge!(group_id: label_parent.id, only_group_labels: true)
          end

          LabelsFinder.new(current_user, search_params).execute
        end

        def create_list(board, params)
          create_list_service =
            ::Boards::Lists::CreateService.new(board.resource_parent, current_user, params)

          create_list_service.execute(board)
        end
      end
    end
  end
end

Mutations::Boards::Lists::Create.prepend_if_ee('::EE::Mutations::Boards::Lists::Create')
