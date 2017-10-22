module Banzai
  module ReferenceParser
    class EpicParser < BaseParser
      self.reference_type = :epic

      def references_relation
        Epic
      end
    end
  end
end
