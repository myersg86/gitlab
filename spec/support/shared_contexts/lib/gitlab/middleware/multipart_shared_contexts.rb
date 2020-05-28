# frozen_string_literal: true

RSpec.shared_context 'multipart middleware context' do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:original_filename) { 'filename' }

  # Rails 5 doesn't combine the GET/POST parameters in
  # ActionDispatch::HTTP::Parameters if action_dispatch.request.parameters is set:
  # https://github.com/rails/rails/blob/aea6423f013ca48f7704c70deadf2cd6ac7d70a1/actionpack/lib/action_dispatch/http/parameters.rb#L41
  def get_params(env)
    req = ActionDispatch::Request.new(env)
    req.GET.merge(req.POST)
  end

  def post_env(rewritten_fields, params)
    token = jwt_encode('rewritten_fields' => rewritten_fields)
    Rack::MockRequest.env_for(
      '/',
      method: 'post',
      params: params,
      described_class::RACK_ENV_KEY => token
    )
  end

  def jwt_encode(params)
    JWT.encode(params.merge('iss' => jwt_issuer), jwt_secret, 'HS256')
  end

  def with_tmp_dir(uploads_sub_dir, storage_path = '')
    Dir.mktmpdir do |dir|
      upload_dir = File.join(dir, storage_path, uploads_sub_dir)
      FileUtils.mkdir_p(upload_dir)

      allow(Rails).to receive(:root).and_return(dir)
      allow(Dir).to receive(:tmpdir).and_return(File.join(Dir.tmpdir, 'tmpsubdir'))
      allow(GitlabUploader).to receive(:root).and_return(File.join(dir, storage_path))

      Tempfile.open('top-level', upload_dir) do |tempfile|
        rewritten = { 'file' => tempfile.path }
        upload_params = { 'name' => original_filename, 'path' => tempfile.path }
        in_params = {
          'file.name' => original_filename,
          'file.path' => tempfile.path,
          'file.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params)
        }

        env = post_env(rewritten, in_params)

        yield dir, env
      end
    end
  end
end
