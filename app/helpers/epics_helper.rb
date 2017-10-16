# TODO: most of the actions might be temporary before we start using Issuables for Epics
module EpicsHelper
  # this probably does not need to be here HOTPATCH
  include MarkupHelper

  # TODO: use issuable_initial_data instead
  def epic_initial_data
    data = {
      endpoint: group_epic_path(@group, @epic),
      canUpdate: can?(current_user, :admin_epic, @group),
      canDestroy: can?(current_user, :admin_epic, @group),
      # issuableRef: @epic.to_reference,
      markdownPreviewPath: preview_markdown_group_epics_path(@group),
      markdownDocsPath: help_page_path('user/markdown'),
      groupPath: group_path(@group),
      initialTitleHtml: markdown_field(@epic, :title),
      initialTitleText: @epic.title,
      initialDescriptionHtml: markdown_field(@epic, :description),
      initialDescriptionText: @epic.description
    }

    # data.merge!(updated_at_by(@epic))

    data.to_json
  end

  def epic_meta_data
    author = @epic.author

    data = {
      created: @epic.created_at,
      author: {
        name: author.name,
        url: "/#{author.username}",
        username: "@#{author.username}",
        src: avatar_icon(@epic.author)
      }
    }

    data.to_json
  end
end
