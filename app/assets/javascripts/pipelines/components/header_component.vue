<script>
import { GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import ciHeader from '~/vue_shared/components/header_ci_component.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import eventHub from '../event_hub';
import pipelineQuery from '../graphql/queries/get_pipeline_header_data.graphql';
import cancelPipelineMutation from '../graphql/mutations/cancel_pipeline.graphql';
import deletePipelineMutation from '../graphql/mutations/delete_pipeline.graphql';
import retryPipelineMutation from '../graphql/mutations/retry_pipeline.graphql';

const DELETE_MODAL_ID = 'pipeline-delete-modal';

export default {
  name: 'PipelineHeaderSection',
  components: {
    ciHeader,
    GlLoadingIcon,
    GlModal,
    LoadingButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    // TODO: This will get removed from the props and the component itself will fetch it right?
    // pipeline: {
    //   type: Object,
    //   required: true,
    // },
    // isLoading: {
    //   type: Boolean,
    //   required: true,
    // },
    pipelineId: {
      type: String,
      required: true,
    },
  },
  apollo: {
    pipeline: {
      query: pipelineQuery,
      variables() {
        return {
          id: this.pipelineId,
        };
      },
      pollInterval: 10000,
      error(error) {},
    },
  },
  data() {
    return {
      pipeline: Object,
      isCanceling: false,
      isRetrying: false,
      isDeleting: false,
    };
  },

  computed: {
    status() {
      return this.pipeline.details && this.pipeline.details.status;
    },
    shouldRenderContent() {
      return !this.isLoading && Object.keys(this.pipeline).length;
    },
    deleteModalConfirmationText() {
      return __(
        'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
      );
    },
  },

  methods: {
    async cancelPipeline() {
      this.isCanceling = true;
      // eventHub.$emit('headerPostAction', this.pipeline.cancel_path);
      await this.$appolo.mutate(cancelPipelineMutation);
    },
    async retryPipeline() {
      this.isRetrying = true;
      // eventHub.$emit('headerPostAction', this.pipeline.retry_path);
      await this.$appolo.mutate(retryPipelineMutation);
    },
    async deletePipeline() {
      this.isDeleting = true;
      // eventHub.$emit('headerDeleteAction', this.pipeline.delete_path);
      await this.$appolo.mutate(deletePipelineMutation);
    },
  },
  DELETE_MODAL_ID,
};
</script>
<template>
  <div class="pipeline-header-container">
    <ci-header
      v-if="shouldRenderContent"
      :status="status"
      :item-id="pipeline.id"
      :time="pipeline.created_at"
      :user="pipeline.user"
      item-name="Pipeline"
    >
      <loading-button
        v-if="pipeline.retry_path"
        :loading="isRetrying"
        :disabled="isRetrying"
        class="js-retry-button btn btn-inverted-secondary"
        container-class="d-inline"
        :label="__('Retry')"
        @click="retryPipeline()"
      />

      <loading-button
        v-if="pipeline.cancel_path"
        :loading="isCanceling"
        :disabled="isCanceling"
        class="js-btn-cancel-pipeline btn btn-danger"
        container-class="d-inline"
        :label="__('Cancel running')"
        @click="cancelPipeline()"
      />

      <loading-button
        v-if="pipeline.delete_path"
        v-gl-modal="$options.DELETE_MODAL_ID"
        :loading="isDeleting"
        :disabled="isDeleting"
        class="js-btn-delete-pipeline btn btn-danger btn-inverted"
        container-class="d-inline"
        :label="__('Delete')"
      />
    </ci-header>

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3 gl-mb-3" />

    <gl-modal
      :modal-id="$options.DELETE_MODAL_ID"
      :title="__('Delete pipeline')"
      :ok-title="__('Delete pipeline')"
      ok-variant="danger"
      @ok="deletePipeline()"
    >
      <p>
        {{ deleteModalConfirmationText }}
      </p>
    </gl-modal>
  </div>
</template>
