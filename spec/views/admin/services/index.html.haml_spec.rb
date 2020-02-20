# frozen_string_literal: true

require 'spec_helper'

describe 'admin/services/index.html.haml' do
  before do
    assign(:services, build_stubbed_list(:service, 1))
  end

  context 'user has not dismissed Service Templates deperacation message' do
    it 'shows the message' do
      allow(view).to receive(:show_service_templates_deprecated?).and_return(true)

      render

      expect(rendered).to have_content('Service templates will be deprecated')
    end
  end

  context 'user has dismissed Service Templates deperacation message' do
    it 'does not show the message' do
      allow(view).to receive(:show_service_templates_deprecated?).and_return(false)

      render

      expect(rendered).not_to have_content('Service templates will be deprecated')
    end
  end
end
