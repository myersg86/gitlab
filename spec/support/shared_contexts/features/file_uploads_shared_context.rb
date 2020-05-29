# frozen_string_literal: true

RSpec.shared_context 'allow local file upload requests' do
  before do
    stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
  end
end

RSpec.shared_context 'disabled upload_middleware_jwt_params_handler' do
  before do
    stub_feature_flags(upload_middleware_jwt_params_handler: false)
    expect_next_instance_of(Gitlab::Middleware::Multipart::Handler) do |handler|
      expect(handler).to receive(:with_open_files).and_call_original
    end
  end
end

RSpec.shared_context 'enabled upload_middleware_jwt_params_handler' do
  before do
    stub_feature_flags(upload_middleware_jwt_params_handler: true)
    expect_next_instance_of(Gitlab::Middleware::Multipart::HandlerForJWTParams) do |handler|
      expect(handler).to receive(:with_open_files).and_call_original
    end
  end
end
