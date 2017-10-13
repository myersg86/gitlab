# TODO: most of the actions might be temporary before we start using Issuables for Epics
module EpicsHelper
  # TODO: use issuable_initial_data instead
  def epic_initial_data
    data = {
      endpoint: group_epic_path(@group, @epic),
      canUpdate: can?(current_user, :admin_epic, @group),
      canDestroy: can?(current_user, :admin_epic, @group),
      # issuableRef: @epic.to_reference,
      # markdownPreviewPath: preview_markdown_path(@project),
      markdownDocsPath: help_page_path('user/markdown'),
      groupPath: group_path(@group),
      # initialTitleHtml: markdown_field(@epic, :title),
      initialTitleText: @epic.title,
      # initialDescriptionHtml: markdown_field(@epic, :description),
      initialDescriptionText: @epic.description,
    }

    # data.merge!(updated_at_by(@epic))

    data.to_json
  end
end
