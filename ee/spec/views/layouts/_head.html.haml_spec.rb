# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/_head' do
  before do
    allow(view).to receive(:experiment_enabled?).and_return(false)
  end

  describe 'pendo' do
    context 'when pendo is enabled' do
      it 'adds a pendo initialization snippet with url', :aggregate_failures do
        allow(Gitlab::CurrentSettings).to receive(:pendo_enabled?).and_return(true)
        allow(Gitlab::CurrentSettings).to receive(:pendo_url).and_return('www.pen.do')

        render

        expect(rendered).to match('pendo.initialize')
        expect(rendered).to match('www.pen.do')
      end
    end

    context 'when pendo is not enabled' do
      it 'do not add pendo snippet' do
        allow(Gitlab::CurrentSettings).to receive(:pendo_enabled?).and_return(false)

        render

        expect(rendered).not_to match('pendo.initialize')
      end
    end
  end
end
