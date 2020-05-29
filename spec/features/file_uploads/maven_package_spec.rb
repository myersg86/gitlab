# frozen_string_literal: true

require 'spec_helper'

describe 'Upload maven package', :api, :js, :capybara_ignore_server_errors do
  include_context 'allow local file upload requests'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:params) { {} }

  let(:url) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}#{api("/projects/#{project.id}/packages/maven/com/example/my-app/1.0/my-app-1.0-20180724.124855-1.jar", personal_access_token: personal_access_token)}" }
  let(:file) { Tempfile.new('file_to_upload') }

  before do
    stub_licensed_features(packages: true)
    stub_package_file_object_storage(enabled: false)
  end

  subject { RestClient.put(url, file) }

  context 'with upload_middleware_jwt_params_handler disabled' do
    include_context 'disabled upload_middleware_jwt_params_handler'

    it 'creates package files' do
      expect { subject }.to change { Packages::PackageFile.count }.by(1)
    end

    it_behaves_like 'file upload requests returns a succesful response'
  end

  context 'with upload_middleware_jwt_params_handler enabled' do
    include_context 'enabled upload_middleware_jwt_params_handler'

    it 'creates package files' do
      expect { subject }.to change { Packages::PackageFile.count }.by(1)
    end

    it_behaves_like 'file upload requests returns a succesful response'
  end
end
