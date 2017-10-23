module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include InternalId
      include Issuable
      include BasicStateMachine
      include Referable

      belongs_to :assignee, class_name: "User"
      belongs_to :group

      validates :group, presence: true
    end

    def to_reference(from = nil, full: nil)
      reference = "#{self.class.reference_prefix}#{iid}"

      full || cross_reference?(from) ? "#{group.to_reference(from, full: full)}#{reference}" : reference
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def cross_reference?(from)
      from && from != group
    end

    def supports_weight?
      false
    end

    module ClassMethods
      def reference_prefix
        '&'
      end

      # Pattern used to extract `&123` epic references from text
      # This pattern supports cross-group  references.
      def reference_pattern
        @reference_pattern ||= %r{
          (#{::Group.reference_pattern})?
          #{Regexp.escape(reference_prefix)}(?<epic>\d+)
        }x
      end

      def link_reference_pattern
        @link_reference_pattern ||= super("issues", /(?<issue>\d+)/)
      end

      def reference_valid?(reference)
        reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
      end
    end
  end
end
