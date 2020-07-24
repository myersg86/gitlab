# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreventForkingHelper do
  let(:group) { create :group }
  let(:owner) { group.owner }
  let(:developer) { create :user}
  let(:users) do
    {
      developer: developer,
      owner: owner
    }
  end

  where(:user, :feature_enabled, :setting, :result) do
    [
      [:developer,  true,  false, false],
      [:developer,  true,  true,  false],
      [:developer,  false, false, false],
      [:developer,  false, true,  false],
      [:owner,      true,  false, false],
      [:owner,      true,  true,  true],
      [:owner,      false, false, false],
      [:owner,      false, true,  false]
    ]
  end

  with_them do
    before do
      group.namespace_settings.update_column(:prevent_forking_outside_group, setting)
      group.add_developer(developer)
      stub_licensed_features(group_forking_protection: feature_enabled)
      allow(helper).to receive(:can?).with(users[user], :change_prevent_group_forking, group) { result }
    end

    it 'returns proper value' do
      expect(helper.can_change_prevent_forking?(users[user], group)).to eq(result)
    end
  end
end
