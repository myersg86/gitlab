require 'spec_helper'

describe Groups::EpicsController do
  let(:group) { create(:group, :public) }
  let(:user)  { create(:user)}

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    def show_epic(format = :html)
      get :show, group_id: group, id: epic.to_param, format: format
    end
    let(:epic) { create(:epic, group: group) }

    context 'when format is HTML' do
      it 'renders template' do
        show_epic

        expect(response.content_type).to eq 'text/html'
        expect(response).to render_template 'groups/ee/epics/show'
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(false)
        end

        it 'returns a not found 404 response' do
          show_epic

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'text/html'
        end
      end
    end

    context 'when format is JSON' do
      it 'returns epic' do
        show_epic(:json)

        # TODO create schema after the decision we'll use epic table is made
        # expect(response).to match_response_schema('epic')
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(false)
        end

        it 'returns a not found 404 response' do
          show_epic(:json)

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'application/json'
        end
      end
    end
  end
end
