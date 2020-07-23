# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Node do
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :provided_by_user, :group) }
  let(:expected_nodes) { [kube_node.merge(kube_node_metrics)] }

  describe '#all' do
    before do
      stub_kubeclient_nodes_and_nodes_metrics(cluster.platform.api_url)
    end

    subject { described_class.new(cluster).all }

    context 'when connection to the cluster is successful' do
      it { is_expected.to eq(expected_nodes) }
    end
  end

  describe '#all_with_errors' do
    let(:empty_nodes) { [] }

    subject { described_class.new(cluster).all_with_errors }

    context 'when connection to the cluster is successful' do
      before do
        stub_kubeclient_nodes_and_nodes_metrics(cluster.platform.api_url)
      end

      it { is_expected.to eq({ nodes: expected_nodes, connection_error: nil }) }
    end

    context 'connection error' do
      using RSpec::Parameterized::TableSyntax

      where(:error, :error_status) do
        SocketError                             | :kubernetes_connection_error
        OpenSSL::X509::CertificateError         | :kubernetes_authentication_error
        StandardError                           | :unknown_error
        Kubeclient::HttpError.new(408, "", nil) | :kubeclient_http_error
      end

      with_them do
        before do
          allow(cluster.kubeclient).to receive(:get_nodes).and_raise(error)
        end

        it { is_expected.to eq({ nodes: empty_nodes, connection_error: error_status }) }
      end
    end

    context 'when an uncategorised error is raised' do
      before do
        allow(cluster.kubeclient.core_client).to receive(:discover)
          .and_raise(StandardError)
      end

      it { is_expected.to eq({ nodes: empty_nodes, connection_error: :unknown_error }) }

      it 'notifies Sentry' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(StandardError), hash_including(cluster_id: cluster.id))
          .once

        subject
      end
    end
  end
end
