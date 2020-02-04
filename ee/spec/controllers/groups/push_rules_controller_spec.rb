# frozen_string_literal: true
require 'spec_helper'

describe Groups::PushRulesController do
  let(:group) { create(:group, :private) }
  let!(:push_rule) { create(:group_push_rule, group: group) }
  let(:user) { create(:user) }

  describe '#show' do
    before do
      sign_in(user)
      group.add_maintainer(user)
    end

    context 'when push rules feature is disabled' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it "returns 404 status" do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when push rules feature is enabled' do
      before do
        stub_licensed_features(push_rules: true)
      end

      it "returns 200 status" do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe '#update' do
    def do_update
      patch :update, params: { group_id: group, push_rule: { prevent_secrets: true } }
    end

    before do
      sign_in(user)
      group.add_maintainer(user)
      stub_licensed_features(push_rules: true)
    end

    it 'updates the push rule' do
      do_update

      expect(response).to have_gitlab_http_status(302)
      expect(group.reload_group_push_rule.prevent_secrets).to be_truthy
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'returns 404' do
        do_update

        expect(response).to have_gitlab_http_status(404)
      end
    end

    shared_examples 'updateable setting' do |rule_attr, updates, new_value|
      it "#{updates ? 'updates' : 'does not update'} the setting" do
        if updates
          expect do
            patch :update, params: { group_id: group, push_rule: { rule_attr => new_value } }
          end.to change { group.reload_group_push_rule.public_send(rule_attr) }.to(new_value)
        else
          expect do
            patch :update, params: { group_id: group, push_rule: { rule_attr => new_value } }
          end.not_to change { group.reload_group_push_rule.public_send(rule_attr) }
        end
      end
    end

    shared_examples 'a setting with global default' do |rule_attr, updates: true, updates_when_global_enabled: true|
      context 'when disabled' do
        before do
          stub_licensed_features(rule_attr => false)
        end
        it_behaves_like 'updateable setting', rule_attr, false, true
      end

      context 'when enabled' do
        before do
          stub_licensed_features(rule_attr => true)
        end
        it_behaves_like 'updateable setting', rule_attr, updates, true
      end

      context 'when global setting is enabled' do
        before do
          stub_licensed_features(rule_attr => true)
          create(:push_rule_sample, rule_attr => true)
        end
        it_behaves_like 'updateable setting', rule_attr, updates_when_global_enabled, false
      end
    end

    PushRule::SETTINGS_WITH_GLOBAL_DEFAULT.each do |rule_attr|
      context "Updating #{rule_attr} rule" do
        context 'as an admin' do
          let(:user) { create(:admin) }

          it_behaves_like 'a setting with global default', rule_attr, updates: true
        end

        context 'as a maintainer user' do
          before do
            group.add_maintainer(user)
          end
          it_behaves_like 'a setting with global default', rule_attr, updates: true, updates_when_global_enabled: false
        end

        context 'as a developer user' do
          before do
            group.add_developer(user)
          end
          it_behaves_like 'a setting with global default', rule_attr, updates: false, updates_when_global_enabled: false
        end
      end
    end
  end
end
