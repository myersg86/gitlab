<script>
import { isSafeURL } from '~/lib/utils/url_utility';
import { GlModal, GlFormGroup, GlFormInput, GlTabs, GlTab } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { IMAGE_TABS, MAX_FILE_SIZE } from '../constants';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlTabs,
    GlTab,
  },
  mixins: [glFeatureFlagMixin()],
  data() {
    return {
      fileError: null,
      urlError: null,
      imageUrl: null,
      description: null,
      tabIndex: IMAGE_TABS.UPLOAD_TAB,
      modalTitle: __('Image Details'),
      okTitle: __('Insert'),
      urlTabTitle: __('By URL'),
      urlLabel: __('Image URL'),
      descriptionLabel: __('Description'),
      fileLabel: __('Select file'),
      uploadTabTitle: __('Upload file'),
    };
  },
  computed: {
    altText() {
      return this.description || __('image');
    },
  },
  methods: {
    show() {
      this.fileError = null;
      this.urlError = null;
      this.imageUrl = null;
      this.description = null;
      this.tabIndex = IMAGE_TABS.UPLOAD_TAB;

      this.$refs.modal.show();
    },
    onOk(event) {
      if (this.glFeatures.sseImageUploads && this.tabIndex === IMAGE_TABS.UPLOAD_TAB) {
        this.submitFile(event);
        return;
      }
      this.submitURL(event);
    },
    submitFile(event) {
      const file = this.$refs.fileInput.files[0];

      if (!this.isValidFile(file)) {
        event.preventDefault();
        return;
      }

      const { altText } = this;

      this.$emit('uploadImage', { file, altText });
    },
    isValidFile(file) {
      if (!file) {
        this.fileError = __('Please choose a file');
        return false;
      }

      const { size } = file;

      if (size > MAX_FILE_SIZE) {
        this.fileError = __('Maximum file size is 2MB. Please select a smaller file');
        return false;
      }

      return true;
    },
    submitURL(event) {
      if (!this.isValidUrl()) {
        event.preventDefault();
        return;
      }

      const { imageUrl, altText } = this;

      this.$emit('addImage', { imageUrl, altText });
    },
    isValidUrl() {
      if (!isSafeURL(this.imageUrl)) {
        this.urlError = __('Please provide a valid URL');
        this.$refs.urlInput.$el.focus();
        return false;
      }

      return true;
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="add-image-modal"
    :title="modalTitle"
    :ok-title="okTitle"
    @ok="onOk"
  >
    <gl-tabs v-if="glFeatures.sseImageUploads" v-model="tabIndex">
      <!-- Upload file Tab -->
      <gl-tab :title="uploadTabTitle">
        <gl-form-group
          class="gl-mt-5 gl-mb-3"
          :label="fileLabel"
          label-for="file-input"
          :state="!Boolean(fileError)"
          :invalid-feedback="fileError"
        >
          <input
            id="file-input"
            ref="fileInput"
            class="gl-mt-3 gl-mb-2"
            type="file"
            accept="image/*"
          />
        </gl-form-group>
      </gl-tab>

      <!-- By URL Tab -->
      <gl-tab :title="urlTabTitle">
        <gl-form-group
          class="gl-mt-5 gl-mb-3"
          :label="urlLabel"
          label-for="url-input"
          :state="!Boolean(urlError)"
          :invalid-feedback="urlError"
        >
          <gl-form-input id="url-input" ref="urlInput" v-model="imageUrl" />
        </gl-form-group>
      </gl-tab>
    </gl-tabs>

    <gl-form-group
      v-else
      class="gl-mt-5 gl-mb-3"
      :label="urlLabel"
      label-for="url-input"
      :state="!Boolean(urlError)"
      :invalid-feedback="urlError"
    >
      <gl-form-input id="url-input" ref="urlInput" v-model="imageUrl" />
    </gl-form-group>

    <!-- Description Input -->
    <gl-form-group :label="descriptionLabel" label-for="description-input">
      <gl-form-input id="description-input" ref="descriptionInput" v-model="description" />
    </gl-form-group>
  </gl-modal>
</template>
