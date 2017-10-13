require 'spec_helper'

describe "Git HTTP requests (Geo)" do
  include ::EE::GeoHelpers
  include GitHttpHelpers
  include WorkhorseHelpers

  set(:project) { create(:project, :repository) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  before do
    stub_licensed_features(geo: true)
    stub_current_geo_node(secondary)
  end

  shared_examples_for 'Geo sync request' do
    subject { response }

    context 'valid Geo JWT token' do
      let(:env) { valid_geo_env }

      it 'returns an OK response' do
        is_expected.to have_gitlab_http_status(:ok)

        expect(response.content_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response).to include('ShowAllRefs' => true)
      end
    end

    context 'post-dated Geo JWT token' do
      let(:env) { valid_geo_env }

      it { travel_to(2.minutes.ago) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'expired Geo JWT token' do
      let(:env) { valid_geo_env }

      it { travel_to(Time.now + 2.minutes) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'invalid Geo JWT token' do
      let(:env) { valid_geo_env }

      before do
        secondary.destroy
      end

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'no Geo JWT token' do
      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'Geo is unlicensed' do
      before do
        stub_licensed_features(geo: false)
      end

      it {  is_expected.to have_http_status(:unauthorized) }
    end
  end

  describe 'GET info_refs' do
    it_behaves_like 'Geo sync request' do
      before do
        get "/#{project.full_path}.git/info/refs", { service: 'git-upload-pack' }, env
      end
    end
  end

  describe 'POST upload_pack' do
    it_behaves_like 'Geo sync request' do
      before do
        post "/#{project.full_path}.git/git-upload-pack", env
      end
    end
  end

  def valid_geo_env
    env = workhorse_internal_api_request_header
    env['HTTP_AUTHORIZATION'] = Gitlab::Geo::BaseRequest.new.authorization

    env
  end
end
