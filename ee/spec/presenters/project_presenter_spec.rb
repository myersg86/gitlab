# frozen_string_literal: true

require 'spec_helper'

describe ProjectPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:presenter) { described_class.new(project, current_user: user) }

  describe '#extra_statistics_buttons' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    let(:security_dashboard_data) do
      OpenStruct.new(is_link: false,
                     label: a_string_including('Security Dashboard'),
                     link: project_security_dashboard_path(project),
                     class_modifier: 'default')
    end

    context 'user is allowed to read security dashboard' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(true)
      end

      it 'has security dashboard link' do
        expect(presenter.extra_statistics_buttons.find { |button| button[:link] == project_security_dashboard_path(project) }).not_to be_nil
      end
    end

    context 'user is not allowed to read security dashboard' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(false)
      end

      it 'has no security dashboard link' do
        expect(presenter.extra_statistics_buttons.find { |button| button[:link] == project_security_dashboard_path(project) }).to be_nil
      end
    end
  end

  describe '#npmrc_data' do
    context 'when user can push and .npmrc does not exist' do
      it 'returns anchor data to add an npmrc file' do
        project.add_developer(user)
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
