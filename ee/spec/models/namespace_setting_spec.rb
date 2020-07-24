# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting do
  let(:group) { create(:group) }
  let(:namespace_settings) { group.namespace_settings }

  describe '#prevent_forking_outside_group?' do
    context 'with feature available' do
      before do
        stub_licensed_features(group_forking_protection: true)
      end

      context 'group with no associated saml provider' do
        before do
          namespace_settings.update!(prevent_forking_outside_group: true)
        end

        it 'returns namespace setting' do
          expect(namespace_settings.prevent_forking_outside_group?).to eq(true)
        end
      end

      context 'group with associated saml provider' do
        before do
          stub_licensed_features(group_saml: true, group_forking_protection: true)
        end

        context 'when it is configured to true on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true, group: group)
          end

          it 'returns true' do
            expect(namespace_settings.prevent_forking_outside_group?).to eq(true)
          end
        end

        context 'when it is configured to false on saml level' do
          before do
            create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: false, group: group)
          end

          it 'returns false' do
            expect(group.prevent_forking_outside_group?).to eq(false)
          end

          context 'when setting is configured on namespace level' do
            before do
              namespace_settings.update!(prevent_forking_outside_group: true)
            end

            it 'returns namespace setting' do
              expect(namespace_settings.prevent_forking_outside_group?).to eq(true)
            end
          end
        end
      end
    end

    context 'without feature available' do
      it 'returns false' do
        expect(group.prevent_forking_outside_group?).to be_falsey
      end
    end
  end
end
