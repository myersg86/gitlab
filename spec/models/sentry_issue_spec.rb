# frozen_string_literal: true

require 'spec_helper'

describe SentryIssue do
  set(:issue) { create(:issue) }

  let(:sentry_issue) { build(:sentry_issue, issue: issue) }

  describe 'Associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    describe 'issue' do
      it 'validates issue presence' do
        sentry_issue.issue = nil

        expect(subject).not_to be_valid
      end

      context 'with existing gitlab issue link' do
        before do
          create(:sentry_issue, issue: issue)
        end

        it 'validates uniqueness' do
          expect(subject).not_to be_valid
        end
      end
    end

    describe 'sentry_issue_identifier' do
      it 'validates sentry_issue_identifier presence' do
        sentry_issue.sentry_issue_identifier = nil

        expect(sentry_issue).not_to be_valid
      end
    end
  end
end
