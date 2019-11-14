# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Redis::RedisConnectionPool do
  describe '.initialize' do
    let(:options) do
      {
        host: 'localhost',
        port: '1234',
        connection_pool_size: {
          unicorn: 1,
          puma: 5,
          sidekiq: 10
        }
      }
    end
    subject { described_class.new(options) }

    it 'segregates GitLab specific config from Redis config' do
      expect(subject.options).to eq(options[:connection_pool_size])
      expect(subject.redis_options).to eq(options.slice(:host, :port))
    end
  end

  describe '.size' do
    context 'when user specified pool size is set' do
      let(:options) do
        {
          connection_pool_size: {
            unicorn: 1,
            puma: 5,
            sidekiq: 10
          }
        }
      end
      subject { described_class.new(options) }

      context 'for unicorn' do
        it 'uses the given pool size' do
          expect(subject.size).to eq(1)
        end
      end

      context 'for puma' do
        before do
          stub_puma
        end

        it 'uses the given pool size' do
          expect(subject.size).to eq(5)
        end
      end

      context 'for sidekiq' do
        before do
          stub_sidekiq
        end

        it 'uses the given pool size' do
          expect(subject.size).to eq(10)
        end
      end
    end

    context 'when no user specified connection_pool_size is set' do
      subject { described_class.new }

      context 'for unicorn' do
        it 'uses a size of round(1 + 50%)' do
          expect(subject.size).to eq(2)
        end
      end

      context 'for puma' do
        before do
          stub_puma(max_threads: 8)
        end

        it 'uses a size of round(worker_threads + 50%)' do
          expect(subject.size).to eq(12)
        end
      end

      context 'for sidekiq' do
        before do
          stub_sidekiq(concurrency: 10)
        end

        it 'uses a size of round(worker_threads + 50%)' do
          expect(subject.size).to eq(15)
        end
      end
    end

    private

    def stub_puma(options = {})
      puma = double('Puma') # can't use class_double, as Puma type not available in test env
      allow(puma).to receive_message_chain(:cli_config, :options).and_return(options)
      stub_const("Puma", puma)
      puma
    end

    def stub_sidekiq(options = {})
      sidekiq = class_double(::Sidekiq)
      allow(sidekiq).to receive(:server?).and_return(true)
      allow(sidekiq).to receive(:options).and_return(options)
      stub_const("Sidekiq", sidekiq)
      sidekiq
    end
  end
end
