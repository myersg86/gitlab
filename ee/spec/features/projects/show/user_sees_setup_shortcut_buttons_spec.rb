# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Show > User sees setup shortcut buttons' do
  include FakeBlobHelpers

  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe '.npmrc button' do
    let(:project) { create(:project, :public, :repository) }

    it 'does not display when there is no package.json file' do
      visit project_path(project)

      page.within('.project-buttons') do
        expect(page).not_to have_link('Add .npmrc')
      end
    end

    it 'displays the add .npmrc button when there is a package.json file' do
      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add package.json",
        file_path: 'package.json',
        file_content: "{}"
      ).execute

      visit project_path(project)

      page.within('.project-buttons') do
        expect(page).to have_link('Add .npmrc')
      end
    end

    it 'does not display the add button when a .npmrc file exists' do
      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add package.json",
        file_path: '.npmrc',
        file_content: "@{package-scope}:registry=foo"
      ).execute

      visit project_path(project)

      page.within('.project-buttons') do
        expect(page).not_to have_link('Add .npmrc')
        expect(page).to have_link('.npmrc')
      end
    end
  end
end
