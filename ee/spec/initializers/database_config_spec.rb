# frozen_string_literal: true

require 'spec_helper'

describe 'Database config initializer for GitLab EE' do
  let(:geo_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }

  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  before do
    stub_primary_database_config
    stub_geo_database_config(pool_size: nil)
  end

  context "when using multi-threaded runtime" do
    let(:max_threads) { 8 }

    before do
      allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(true)
      allow(Gitlab::Runtime).to receive(:max_threads).and_return(max_threads)
    end

    context "and the runtime is Sidekiq" do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      context "and no existing pool size is set" do
        it "sets it to the max number of worker threads" do
          expect { subject }.to change { geo_pool.size }.from(nil).to(max_threads)
        end
      end

      context "and the existing pool size is smaller than the max number of worker threads" do
        before do
          stub_geo_database_config(pool_size: max_threads - 1)
        end

        it "sets it to the max number of worker threads" do
          expect { subject }.to change { geo_pool.size }.by(1)
        end
      end

      context "and the existing pool size is larger than the max number of worker threads" do
        before do
          stub_geo_database_config(pool_size: max_threads + 1)
        end

        it "keeps the configured pool size" do
          expect { subject }.not_to change { geo_pool.size }
        end
      end

      context "and the resulting pool size remains smaller than the original pool size" do
        before do
          stub_geo_database_config(pool_size: 5)
          allow(geo_pool).to receive(:size).and_return(4)
        end

        it "raises an exception" do
          expect { subject }.to raise_error(RuntimeError)
        end
      end
    end
  end

  context "when using single-threaded runtime" do
    it "does nothing" do
      expect { subject }.not_to change { geo_pool.size }
    end
  end

  # Primary DB config is tested in spec/initializers/database_config_spec.rb
  def stub_primary_database_config
    pool = instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool)
    allow(pool).to receive(:size).and_return(10)
    allow(ActiveRecord::Base).to receive(:establish_connection).and_return(pool)
  end

  def stub_geo_database_config(pool_size:)
    config = {
      'adapter' => 'postgresql',
      'host' => 'db.host.com',
      'pool' => pool_size
    }.compact

    allow(geo_pool).to receive(:size) { config['pool'] }
    allow(Geo::TrackingBase).to receive(:establish_connection).and_return(geo_pool)
    allow(Rails.configuration).to receive(:geo_database).and_return(config)
  end
end
