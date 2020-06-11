# frozen_string_literal: true

module Terraform
  class VersionedStateUploader < StateUploader
    def filename
      "#{model.version}.tfstate"
    end

    def store_dir
      "#{project_id}/#{model.uuid}"
    end
  end
end
