# frozen_string_literal: true

require 'spec_helper'

describe SentryIssue do
  set(:issue) { create(:issue) }

  subject { create(:sentry_issue, issue: issue) }

  describe 'Associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    describe 'issue' do
      it 'validates issue presence' do
        subject.issue = nil
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:issue]).to include("can't be blank")
      end

      context 'with existing gitlab issue link' do
        before do
          create(:sentry_issue, issue: issue)
        end

        it 'raises and error if issue is not unique' do
          expect{ subject }.to raise_error(
            ActiveRecord::RecordInvalid,
            'Validation failed: Issue has already been taken'
          )
        end
      end
    end

    describe 'sentry_issue_identifier' do
      it 'validates sentry_issue_identifier presence' do
        subject.sentry_issue_identifier = nil
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:sentry_issue_identifier]).to include("can't be blank")
      end
    end

    describe 'sentry_event_identifier' do
      it 'passes validation with alphanumeric string' do
        expect(subject).to be_valid
      end

      it 'fails validation when sentry_event_identifier includes non-alphanumeric characters' do
        subject.sentry_event_identifier = '-/321<script>/?-/$%'
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:sentry_event_identifier]).to include('alphanumeric characters only')
      end

      it 'validates sentry_event_identifier presence' do
        subject.sentry_event_identifier = nil
        expect(subject).not_to be_valid
      end
    end
  end
end
