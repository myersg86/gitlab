<script>
import { __, s__, sprintf } from '~/locale';
import { GlFormGroup, GlFormInput, GlFormRadioGroup, GlFormTextarea } from '@gitlab/ui';

const defaultFileName = dashboard => dashboard.path.split('/').reverse()[0];

const DEFAULT = 'DEFAULT';
const NEW = 'NEW';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormRadioGroup,
    GlFormTextarea,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      form: {
        dashboard: this.dashboard.path,
        fileName: defaultFileName(this.dashboard),
        commitMessage: '',
      },
      branchName: '',
      branchOption: DEFAULT,
      branchOptions: [
        {
          value: DEFAULT,
          html: sprintf(
            __('Commit to %{branchName} branch'),
            {
              branchName: `<strong>${this.defaultBranch}</strong>`,
            },
            false,
          ),
        },
        { value: NEW, text: __('Create new branch') },
      ],
    };
  },
  computed: {
    defaultCommitMsg() {
      return sprintf(s__('Metrics|Create custom dashboard %{fileName}'), {
        fileName: this.form.fileName,
      });
    },
    fileNameState() {
      if (this.form.fileName && !this.form.fileName.endsWith('.yml')) {
        return false;
      }
      return true;
    },
    fileNameFeedback() {
      if (!this.fileNameState) {
        return s__('The file name should have a .yml extension');
      }
      return null;
    },
  },
  mounted() {
    this.change();
  },
  methods: {
    change() {
      this.$emit('change', {
        ...this.form,
        commitMessage: this.form.commitMessage ? this.form.commitMessage : this.defaultCommitMsg,
        branch: this.branchOption === NEW ? this.branchName : this.defaultBranch,
      });
    },
    focus(option) {
      if (option === NEW) {
        this.$refs.branchName.$el.focus();
      }
    },
  },
};
</script>
<template>
  <form @change="change">
    <p class="text-muted">
      {{
        s__(`You can save a copy of this dashboard to your repository
      so it can be customized. Select a file name and branch to 
      save it.`)
      }}
    </p>
    <gl-form-group
      :label="s__('File name')"
      :state="fileNameState"
      :invalid-feedback="fileNameFeedback"
      label-size="sm"
      label-for="fileName"
    >
      <gl-form-input id="fileName" ref="fileName" v-model="form.fileName" :required="true" />
    </gl-form-group>
    <gl-form-group :label="s__('Branch')" label-size="sm" label-for="branch">
      <gl-form-radio-group
        ref="branchOption"
        v-model="branchOption"
        :checked="branchOptions[0].value"
        :stacked="true"
        :options="branchOptions"
        @change="focus"
      />
      <gl-form-input id="branchName" ref="branchName" v-model="branchName" />
    </gl-form-group>
    <gl-form-group
      :label="s__('Commit message (optional)')"
      label-size="sm"
      label-for="commitMessage"
    >
      <gl-form-textarea
        id="commitMessage"
        ref="commitMessage"
        v-model="form.commitMessage"
        :placeholder="defaultCommitMsg"
      />
    </gl-form-group>
  </form>
</template>
