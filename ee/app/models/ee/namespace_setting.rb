# frozen_string_literal: true

module EE
  module NamespaceSetting
    extend ActiveSupport::Concern

    delegate :root_ancestor, to: :namespace

    def prevent_forking_outside_group?
      return false unless namespace.feature_available?(:group_forking_protection)

      root_ancestor.saml_provider&.prohibited_outer_forks? || root_ancestor.namespace_settings&.prevent_forking_outside_group
    end
  end
end
