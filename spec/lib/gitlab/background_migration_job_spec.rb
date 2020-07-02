# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigrationJob do
  describe '.for_migration' do
    let!(:job1) { create(:background_migration_job, name: 'OtherJob') }
    let!(:job2) { create(:background_migration_job) }
    let!(:job3) { create(:background_migration_job, arguments: ['hi', 2]) }

    context 'when no arguments are passed' do
      it 'returns jobs matching name only' do
        relation = described_class.for_migration('TestJob')

        expect(relation.pluck(:name).uniq).to contain_exactly('TestJob')
      end
    end

    context 'when arguments are passed' do
      it 'returns jobs matching name and arguments' do
        relation = described_class.for_migration('TestJob', arguments: ['hi', 2])

        expect(relation.count).to eq(1)
        expect(relation.first).to have_attributes(name: 'TestJob', arguments: ['hi', 2])
      end
    end
  end

  describe '.complete_all' do
    let!(:job1) { create(:background_migration_job, name: 'OtherJob') }
    let!(:job2) { create(:background_migration_job, start_id: 101, end_id: 200) }
    let!(:job3) { create(:background_migration_job) }
    let!(:job4) { create(:background_migration_job) }

    it 'marks all matching jobs complete' do
      expect { described_class.complete_all('TestJob', 1, 100) }
        .to change { described_class.completed.count }.from(0).to(2)

      expect(job3.reload).to be_completed
      expect(job4.reload).to be_completed
    end

    context 'when the job has additional arguments' do
      let!(:job5) { create(:background_migration_job, arguments: ['hi', 2]) }

      it 'marks all matching jobs complete' do
        expect { described_class.complete_all('TestJob', 1, 100, arguments: ['hi', 2]) }
          .to change { described_class.completed.count }.from(0).to(1)

        expect(job5.reload).to be_completed
      end
    end
  end
end
