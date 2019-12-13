# frozen_string_literal: true

require 'spec_helper'

describe ProjectPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:presenter) { described_class.new(project, current_user: user) }

  describe '#extra_statistics_buttons' do
    context 'user is allowed to read security dashboard' do
      it 'has security dashboard link' do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(true)

        expect(presenter.security_dashboard_data).to have_attributes(is_link: false,
                                                                     label: a_string_including('Security Dashboard'),
                                                                     link: project_security_dashboard_path(project),
                                                                     class_modifier: 'default')
      end
    end

    context 'user is not allowed to read security dashboard' do
      it 'has no security dashboard link' do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(false)

        expect(presenter.security_dashboard_data).to be_nil
      end
    end
  end

  describe '#npmrc_data' do
    context 'when user can push and .npmrc does not exist' do
      it 'returns anchor data to add an npmrc file' do
        project.add_developer(user)
        allow(project.repository).to receive(:file_on_head).with(:package_json).and_return(true)
        allow(project.repository).to receive(:npmrc).and_return(nil)

        expect(presenter.npmrc_anchor_data).to have_attributes(is_link: false,
                                                               label: a_string_including('Add .npmrc'),
                                                               link: presenter.add_npmrc_path)
      end
    end

    context 'when .npmrc exists' do
      it 'returns anchor data to view the npmrc file' do
        allow(project.repository).to receive(:npmrc).and_return(double(name: 'npmrc'))

        expect(presenter.npmrc_anchor_data).to have_attributes(is_link: false,
                                                               label: a_string_including('.npmrc'),
                                                               link: presenter.npmrc_path)
      end
    end
  end
end
