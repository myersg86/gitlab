# frozen_string_literal: true

require 'spec_helper'

require 'tempfile'

describe Gitlab::Middleware::Multipart do
  include_context 'multipart middleware context'

  let(:jwt_issuer) { 'gitlab-workhorse' }
  let(:jwt_secret) { Gitlab::Workhorse.secret }

  RSpec.shared_examples_for 'multipart upload files' do
    it 'opens top-level files' do
      Tempfile.open('top-level') do |tempfile|
        rewritten = { 'file' => tempfile.path }
        upload_params = { 'name' => original_filename, 'path' => tempfile.path, 'remote_id' => remote_id, 'size' => file_size }
        in_params = {
          'file.name' => original_filename,
          'file.path' => tempfile.path,
          'file.remote_id' => remote_id,
          'file.size' => file_size,
          'file.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params)
        }

        env = post_env(rewritten, in_params)

        expect_uploaded_file(tempfile, %w(file))

        middleware.call(env)
      end
    end

    it 'opens files one level deep' do
      Tempfile.open('one-level') do |tempfile|
        rewritten = { 'user[avatar]' => tempfile.path }
        upload_params = { 'name' => original_filename, 'path' => tempfile.path, 'remote_id' => remote_id, 'size' => file_size }
        in_params = {
          'user' => {
            'avatar' => {
              '.name' => original_filename,
              '.path' => file_path,
              '.remote_id' => remote_id,
              '.size' => file_size,
              '.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params)
            }
          }
        }

        env = post_env(rewritten, in_params)

        expect_uploaded_file(tempfile, %w(user avatar))

        middleware.call(env)
      end
    end

    it 'opens files two levels deep' do
      Tempfile.open('two-levels') do |tempfile|
        rewritten = { 'project[milestone][themesong]' => tempfile.path }
        upload_params = { 'name' => original_filename, 'path' => tempfile.path, 'remote_id' => remote_id, 'size' => file_size }
        in_params = {
          'project' => {
            'milestone' => {
              'themesong' => {
                '.name' => original_filename,
                '.path' => file_path,
                '.remote_id' => remote_id,
                '.size' => file_size,
                '.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params)
              }
            }
          }
        }

        env = post_env(rewritten, in_params)

        expect_uploaded_file(tempfile, %w(project milestone themesong))

        middleware.call(env)
      end
    end

    it 'opens multiple files on multiple levels deep' do
      Tempfile.open('level1') do |tempfile_level1|
        Tempfile.open('level2') do |tempfile_level2|
          Tempfile.open('level3') do |tempfile_level3|
            rewritten = { 'level1_file' => tempfile_level1.path, 'level1[level2_file]' => tempfile_level2.path, 'level1[level2][level3_file]' => tempfile_level3.path }
            upload_params_level1 = { 'name' => original_filename, 'remote_id' => remote_id, 'size' => file_size, 'path' => tempfile_level1.path }
            upload_params_level2 = { 'name' => original_filename, 'remote_id' => remote_id, 'size' => file_size, 'path' => tempfile_level2.path }
            upload_params_level3 = { 'name' => original_filename, 'remote_id' => remote_id, 'size' => file_size, 'path' => tempfile_level3.path }
            in_params = {
              'level1_file.name' => original_filename,
              'level1_file.remote_id' => remote_id,
              'level1_file.size' => file_size,
              'level1_file.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params_level1),
              'level1' => {
                'level2_file' => {
                  '.name' => original_filename,
                  '.remote_id' => remote_id,
                  '.size' => file_size,
                  '.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params_level2)
                },
                'level2' => {
                  'level3_file' => {
                    '.name' => original_filename,
                    '.remote_id' => remote_id,
                    '.size' => file_size,
                    '.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params_level3)
                  }
                }
              }
            }

            env = post_env(rewritten, in_params)

            expect_uploaded_file([tempfile_level1, tempfile_level2, tempfile_level3], %w(level1_file), %w(level1 level2_file), %w(level1 level2 level3_file))

            middleware.call(env)
          end
        end
      end
    end

    def expect_uploaded_file(tempfiles, *paths)
      expect(app).to receive(:call) do |env|
        Array.wrap(tempfiles)
             .zip(paths)
             .each do |tempfile, path|
          file = get_params(env).dig(*path)
          expect(file).to be_a(::UploadedFile)
          expect(file.original_filename).to eq(original_filename)

          if remote_id
            expect(file.remote_id).to eq(remote_id)
            expect(file.path).to be_nil
          else
            expect(file.path).to eq(File.realpath(tempfile.path))
            expect(file.remote_id).to be_nil
          end
        end
      end
    end
  end

  RSpec.shared_examples_for 'handling CI artifact upload' do
    it 'uploads both file and metadata' do
      Tempfile.open('file') do |file|
        Tempfile.open('metadata') do |metadata|
          rewritten = { 'file' => file.path, 'metadata' => metadata.path }
          file_upload_params = { 'name' => 'file.txt', 'path' => file.path, 'remote_id' => file_remote_id, 'size' => file_size }
          metadata_upload_params = { 'name' => 'metadata.gz', 'path' => metadata.path }
          in_params = {
            'file.name' => 'file.txt',
            'file.path' => file_path,
            'file.remote_id' => file_remote_id,
            'file.size' => file_size,
            'file.gitlab-workhorse-upload' => jwt_encode('upload' => file_upload_params),
            'metadata.name' => 'metadata.gz',
            'metadata.gitlab-workhorse-upload' => jwt_encode('upload' => metadata_upload_params)
          }

          env = post_env(rewritten, in_params)

          with_expected_uploaded_artifact_files(file, metadata) do |uploaded_file, uploaded_metadata|
            expect(uploaded_file).to be_a(::UploadedFile)
            expect(uploaded_file.original_filename).to eq('file.txt')

            if file_remote_id
              expect(uploaded_file.remote_id).to eq(file_remote_id)
              expect(uploaded_file.size).to eq(file_size)
              expect(uploaded_file.path).to be_nil
            else
              expect(uploaded_file.path).to eq(File.realpath(file.path))
              expect(uploaded_file.remote_id).to be_nil
            end

            expect(uploaded_metadata).to be_a(::UploadedFile)
            expect(uploaded_metadata.original_filename).to eq('metadata.gz')
            expect(uploaded_metadata.path).to eq(File.realpath(metadata.path))
            expect(uploaded_metadata.remote_id).to be_nil
          end

          middleware.call(env)
        end
      end
    end

    def with_expected_uploaded_artifact_files(file, metadata)
      expect(app).to receive(:call) do |env|
        file = get_params(env).dig('file')
        metadata = get_params(env).dig('metadata')

        yield file, metadata
      end
    end
  end

  RSpec.shared_examples_for 'supporting all upload cases' do
    context 'with remote file' do
      let(:remote_id) { 'someid' }
      let(:file_size) { 300 }
      let(:file_path) { '' }

      it_behaves_like 'multipart upload files'
    end

    context 'with remote file and a file path set' do
      let(:remote_id) { 'someid' }
      let(:file_size) { 300 }
      let(:file_path) { 'not_a_valid_file_path' } # file path will come from the upload params

      it_behaves_like 'multipart upload files'
    end

    context 'with local file' do
      let(:remote_id) { nil }
      let(:file_size) { nil }
      let(:file_path) { 'not_a_valid_file_path' } # file path will come from the upload params

      it_behaves_like 'multipart upload files'
    end

    context 'with remote CI artifact upload' do
      let(:file_remote_id) { 'someid' }
      let(:file_size) { 300 }
      let(:file_path) { 'not_a_valid_file_path' } # file path will come from the upload params

      it_behaves_like 'handling CI artifact upload'
    end

    context 'with local CI artifact upload' do
      let(:file_remote_id) { nil }
      let(:file_size) { nil }
      let(:file_path) { 'not_a_valid_file_path' } # file path will come from the upload params

      it_behaves_like 'handling CI artifact upload'
    end

    it 'allows files in uploads/tmp directory' do
      with_tmp_dir('public/uploads/tmp') do |dir, env|
        expect(app).to receive(:call) do |env|
          expect(get_params(env)['file']).to be_a(::UploadedFile)
        end

        middleware.call(env)
      end
    end

    it 'allows files in the job artifact upload path' do
      with_tmp_dir('artifacts') do |dir, env|
        expect(JobArtifactUploader).to receive(:workhorse_upload_path).and_return(File.join(dir, 'artifacts'))
        expect(app).to receive(:call) do |env|
          expect(get_params(env)['file']).to be_a(::UploadedFile)
        end

        middleware.call(env)
      end
    end

    it 'allows files in the lfs upload path' do
      with_tmp_dir('lfs-objects') do |dir, env|
        expect(LfsObjectUploader).to receive(:workhorse_upload_path).and_return(File.join(dir, 'lfs-objects'))
        expect(app).to receive(:call) do |env|
          expect(get_params(env)['file']).to be_a(::UploadedFile)
        end

        middleware.call(env)
      end
    end

    it 'allows symlinks for uploads dir' do
      Tempfile.open('two-levels') do |tempfile|
        symlinked_dir = '/some/dir/uploads'
        symlinked_path = File.join(symlinked_dir, File.basename(tempfile.path))

        rewritten = { 'file' => symlinked_path }
        upload_params = { 'name' => original_filename, 'path' => symlinked_path }
        in_params = {
          'file.name' => original_filename,
          'file.path' => symlinked_path,
          'file.gitlab-workhorse-upload' => jwt_encode('upload' => upload_params)
        }

        env = post_env(rewritten, in_params)

        allow(FileUploader).to receive(:root).and_return(symlinked_dir)
        allow(UploadedFile).to receive(:allowed_paths).and_return([symlinked_dir, Gitlab.config.uploads.storage_path])
        allow(File).to receive(:realpath).and_call_original
        allow(File).to receive(:realpath).with(symlinked_dir).and_return(Dir.tmpdir)
        allow(File).to receive(:realpath).with(symlinked_path).and_return(tempfile.path)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(symlinked_dir).and_return(true)

        # override Dir.tmpdir because this dir is in the list of allowed paths
        # and it would match FileUploader.root path (which in this test is linked
        # to /tmp too)
        allow(Dir).to receive(:tmpdir).and_return(File.join(Dir.tmpdir, 'tmpsubdir'))

        expect(app).to receive(:call) do |env|
          expect(get_params(env)['file']).to be_a(::UploadedFile)
        end

        middleware.call(env)
      end
    end
  end

  context 'with the wrong secret' do
    let(:jwt_secret) { 'x' * 32 }

    it 'rejects headers' do
      env = post_env({ 'file' => '/var/empty/nonesuch' }, {})

      expect { middleware.call(env) }.to raise_error(JWT::VerificationError)
    end
  end

  context 'with wrong issuer' do
    let(:jwt_issuer) { 'acme-inc' }

    it 'rejects headers' do
      env = post_env({ 'file' => '/var/empty/nonesuch' }, {})

      expect { middleware.call(env) }.to raise_error(JWT::InvalidIssuerError)
    end
  end

  context 'with invalid rewritten field' do
    invalid_field_names = [
      '[file]',
      ';file',
      'file]',
      ';file]',
      'file]]',
      'file;;'
    ]

    invalid_field_names.each do |invalid_field_name|
      it "rejects invalid rewritten field name #{invalid_field_name}" do
        env = post_env({ invalid_field_name => nil }, {})

        expect { middleware.call(env) }.to raise_error(RuntimeError, "invalid field: \"#{invalid_field_name}\"")
      end
    end
  end

  context 'with upload_middleware_jwt_params_handler disabled' do
    before do
      stub_feature_flags(upload_middleware_jwt_params_handler: false)
    end

    it_behaves_like 'supporting all upload cases'
  end

  context 'with upload_middleware_jwt_params_handler enabled' do
    before do
      stub_feature_flags(upload_middleware_jwt_params_handler: true)
    end

    it_behaves_like 'supporting all upload cases'
  end
end
