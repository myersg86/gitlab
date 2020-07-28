# frozen_string_literal: true

module Groups
  module Security
    class VulnerabilitiesController < Groups::ApplicationController
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :group

      def index
        @vulnerabilities = group.vulnerabilities.page(params[:page])
      end
    end
  end
end

