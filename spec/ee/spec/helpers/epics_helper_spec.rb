require 'spec_helper'

# TODO: create specs
describe EpicsHelper do
  describe '#epic_initial_data' do
    let(:user) { create(:user) }

    # it 'returns the correct hash' do
    #   @group = create(:group)
    #   @epic = create(:epic, group: @group)

    #   expected_data = {
    #     endpoint: "/groups/#{@group.path}/#{@epic.iid}",
    #     # canUpdate: false,
    #     # canDestroy: false,
    #     markdownPreviewPath: "/groups/#{@group.path}/epics/preview_markdown",
    #     markdownDocsPath: 'user/markdown',
    #     groupPath: "/groups/#{@group.path}",
    #     initialTitleHtml: @epic.title_html,
    #     initialTitleText: @epic.title,
    #     initialDescriptionHtml: @epic.description_html,
    #     initialDescriptionText: @epic.description
    #   }

    #   expect(JSON.parse(epic_initial_data)).to eq(expected_data)
    # end
  end
end
