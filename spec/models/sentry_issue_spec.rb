# frozen_string_literal: true

require 'spec_helper'

describe SentryIssue do
  set(:project) { create(:project) }
  set(:issue) { create(:issue) }

  subject { create(:sentry_issue, project: project, issue: issue) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    context 'sentry_event_identifier' do
      it 'passes validation with 32 character string' do
        expect(subject).to be_valid
      end

      context 'when sentry_event_identifier is over 32 chars' do
        before do
          subject.sentry_event_identifier = SecureRandom.hex(40)
        end

        it 'fails validation' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:sentry_event_identifier]).to include('is the wrong length (should be 32 characters)')
        end
      end

      context 'when sentry_event_identifier is under 32 chars' do
        before do
          subject.sentry_event_identifier = SecureRandom.hex(1)
        end

        it 'fails validation' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:sentry_event_identifier]).to include('is the wrong length (should be 32 characters)')
        end
      end

      context 'when sentry_event_identifier includes non-alphanumeric characters' do
        before do
          subject.sentry_event_identifier = '-/321<script>/?-/$%'
        end

        it 'fails validation' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:sentry_event_identifier]).to include('alphanumeric characters only')
        end
      end
    end
  end
end
