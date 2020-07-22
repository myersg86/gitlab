# frozen_string_literal: true

module DesignManagement
  class MoveDesignsService < DesignService
    # @param user [User] The current user
    # @param [Hash] params
    # @option params [DesignManagement::Design] :current_design
    # @option params [DesignManagement::Design] :previous_design (nil)
    # @option params [DesignManagement::Design] :next_design (nil)
    def initialize(user, params)
      super(nil, user, params.merge(issue: nil))
    end

    def execute
      # TODO: move into RelativePositioning#move_between
      return error(:CannotMove) unless current_user.can?(:move_designs, current_design)
      return error(:NotDistinct) unless all_distinct?
      return error(:NotAdjacent) if any_in_gap?
      return error(:NotSameIssue) unless all_same_issue?

      move!
      success
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def success
      ServiceResponse.success
    end

    private

    def move!
      if previous_design || next_design
        current_design.move_between(previous_design, next_design)
      else
        current_design.move_to_start
      end
    end

    def all_distinct?
      ids.uniq.size == ids.size
    end

    def any_in_gap?
      return false unless previous_design && next_design

      !previous_design.immediately_before?(next_design)
    end

    def all_same_issue?
      issue.designs.id_in(ids).count == ids.size
    end

    def ids
      @ids ||= [current_design, previous_design, next_design].compact.map(&:id)
    end

    def current_design
      @current_design ||= params.fetch(:current_design)
    end

    def issue
      current_design.issue
    end

    def previous_design
      params[:previous_design]
    end

    def next_design
      params[:next_design]
    end
  end
end
