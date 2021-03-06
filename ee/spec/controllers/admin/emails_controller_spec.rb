# frozen_string_literal: true

require 'spec_helper'

describe Admin::EmailsController, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  describe 'GET #show' do
    subject { get :show }

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'when `send_emails_from_admin_area` feature is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: true)
        end

        it 'responds with 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when `send_emails_from_admin_area` feature is disabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:recipients) { 'all' }
    let(:email_subject) { 'subject' }
    let(:body) { 'body' }

    subject do
      post :create, params: {
        recipients: recipients,
        subject: email_subject,
        body: body
      }
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'when `send_emails_from_admin_area` feature is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: true)
        end

        context 'when emails from admin area are not rate limited' do
          it 'triggers the service to send emails' do
            expect_next_instance_of(Admin::EmailService, recipients, email_subject, body) do |email_service|
              expect(email_service).to receive(:execute)
            end

            subject
          end

          it 'redirects to `admin_email_path` with success notice' do
            subject

            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(admin_email_path)
            expect(flash[:notice]).to eq('Email sent')
          end
        end

        context 'when emails from admin area are rate limited' do
          let(:lease_key) { Admin::EmailService::LEASE_KEY }
          let(:timeout) { Admin::EmailService::DEFAULT_LEASE_TIMEOUT }

          before do
            stub_exclusive_lease(lease_key, timeout: timeout)
          end

          it 'does not trigger the service to send emails' do
            expect(Admin::EmailService).not_to receive(:new)

            subject
          end

          it 'redirects to `admin_email_path`' do
            subject

            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(admin_email_path)
            expect(flash[:alert]).to eq('Email could not be sent')
          end
        end
      end

      context 'when `send_emails_from_admin_area` feature is disabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
        end

        it 'does not trigger the service to send emails' do
          expect(Admin::EmailService).not_to receive(:new)

          subject
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
