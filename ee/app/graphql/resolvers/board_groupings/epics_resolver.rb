# frozen_string_literal: true

module Resolvers
  module BoardGroupings
    class EpicsResolver < BaseResolver

    type Types::EpicType, null: true

    def resolve(**args)
      @board = object.respond_to?(:sync) ? object.sync : object

      return [] unless board.present?
      return [] unless epic_feature_enabled?

      EpicsFinder.new(context[:current_user], args.merge(board: board, group_id: group.id)).execute
    end

    private

    # def ready?(**args)
    #   # raise Gitlab::Graphql::Errors::ArgumentError "Board ID is not in that project or group" if
    #
    #   super(args)
    # end

     attr_reader :board

      def epic_feature_enabled?
        group.feature_available?(:epics)
      end

      def group
        parent = board.resource_parent
        parent.is_a?(Group) ? parent : parent.group
      end
    end
  end
end
