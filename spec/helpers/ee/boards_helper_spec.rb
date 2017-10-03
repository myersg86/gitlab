require "spec_helper"

describe EE::BoardsHelper do
  describe '#build_issue_link_base' do
    let(:group) { create(:group, path: 'one') }
    let(:group_board) { create(:board, group: group) }

    it 'returns a group issue link base' do
      assign(:board, group_board)

      expect(helper.build_issue_link_base).to eq('/one/:project_path/issues')
    end

    describe 'subgroup board' do
      let(:subgroup) { create(:group, parent: group, path: 'two') }
      let(:subgroup_board) { create(:board, group: subgroup) }

      it 'returns a subgroup issue link base' do
        assign(:board, subgroup_board)

        expect(helper.build_issue_link_base).to eq('/one/two/:project_path/issues')
      end
    end
  end
end
