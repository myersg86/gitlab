# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191209074743_populate_index_status.rb')

describe PopulateIndexStatus, :migration, :sidekiq do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:index_statuses) { table(:index_statuses) }
  let(:namespace1) { namespaces.create(name: 'gitlab org', path: 'gitlab-org') }
  let(:namespace2) { namespaces.create(name: 'gitlab com', path: 'gitlab-com') }

  def create_project(id, options = {})
    default_options = {
      id: id,
      namespace_id: namespace.id,
      name: 'foo',
    }

    projects.create(default_options.merge(options))
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    create_project(id: 1, namespace_id: namespace1.id)
    create_project(id: 2, namespace_id: namespace1.id)
    create_project(id: 3, namespace_id: namespace1.id)
    create_project(id: 4, namespace_id: namespace2.id)
    create_project(id: 5, namespace_id: namespace2.id)
    create_project(id: 6, namespace_id: namespace2.id)
  end

  context 'when elasticsearch_indexing is false' do
    it 'does nothing' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(8.minutes, 2, 4)

          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(16.minutes, 6, 6)

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  context 'when not elasticsearch_limit_indexing' do
  end

  context 'when elasticsearch_limit_indexing' do
  end

  it 'correctly schedules background migrations' do
    create_project(1, approvals_before_merge: 0)
    create_project(2)
    create_project(3, approvals_before_merge: 0)
    create_project(4)
    create_project(5, approvals_before_merge: 0)
    create_project(6)

    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(8.minutes, 2, 4)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(16.minutes, 6, 6)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end

  context 'for FOSS version' do
    before do
      allow(Gitlab).to receive(:ee?).and_return(false)
    end

    it 'does not schedule any jobs' do
      create_project(2)

      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(0)
        end
      end
    end
  end
end
