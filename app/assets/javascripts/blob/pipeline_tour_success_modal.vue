<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import Cookies from 'js-cookie';
import { glEmojiTag } from '~/emoji';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  beginnerLink:
    'https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/',
  exampleLink: 'https://docs.gitlab.com/ee/ci/examples/',
  codeQualityLink: 'https://docs.gitlab.com/ee/user/project/merge_requests/code_quality.html',
  bodyMessage: s__(
    `MR widget|The pipeline will test your code on every commit. A %{codeQualityLinkStart}code quality report%{codeQualityLinkEnd} will appear in your merge requests to warn you about potential code degradations.`,
  ),
  helpMessage: s__(
    `MR widget|Take a look at our %{beginnerLinkStart}Beginner's Guide to Continuous Integration%{beginnerLinkEnd} and our %{exampleLinkStart}examples of GitLab CI/CD%{exampleLinkEnd} to learn more.`,
  ),
  pipelinesButton: s__('MR widget|See your pipeline in action'),
  mergeRequestButton: s__('MR widget|Back to the Merge request'),
  modalTitle: sprintf(
    __("That's it, well done!%{celebrate}"),
    {
      celebrate: glEmojiTag('tada'),
    },
    false,
  ),
  goToTrackValuePipelines: 10,
  goToTrackValueMergeRequest: 20,
  trackEvent: 'click_button',
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  mixins: [trackingMixin],
  props: {
    goToPipelinesPath: {
      type: String,
      required: true,
    },
    projectMergeRequestsPath: {
      type: String,
      required: true,
    },
    commitCookie: {
      type: String,
      required: true,
    },
    humanAccess: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      trackLabel: 'congratulate_first_pipeline',
    };
  },
  computed: {
    tracking() {
      return {
        label: this.trackLabel,
        property: this.humanAccess,
      };
    },
    goToMergeRequestPath() {
      return Cookies.get(this.commitCookie) || this.projectMergeRequestsPath;
    },
  },
  mounted() {
    this.track();
    this.disableModalFromRenderingAgain();
  },
  methods: {
    disableModalFromRenderingAgain() {
      Cookies.remove(this.commitCookie);
    },
  },
};
</script>
<template>
  <gl-modal
    visible
    size="sm"
    :title="$options.modalTitle"
    modal-id="success-pipeline-modal-id-not-used"
  >
    <p>
      <gl-sprintf :message="$options.bodyMessage">
        <template #codeQualityLink="{content}">
          <gl-link :href="$options.codeQualityLink" target="_blank" class="font-size-inherit">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-sprintf :message="$options.helpMessage">
      <template #beginnerLink="{content}">
        <gl-link :href="$options.beginnerLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
      <template #exampleLink="{content}">
        <gl-link :href="$options.exampleLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
    <template #modal-footer>
      <gl-link
        ref="goToMergeRequest"
        :href="goToMergeRequestPath"
        class="btn"
        :data-track-property="humanAccess"
        :data-track-value="$options.goToTrackValueMergeRequest"
        :data-track-event="$options.trackEvent"
        :data-track-label="trackLabel"
      >
        {{ $options.mergeRequestButton }}
      </gl-link>
      <a
        ref="goToPipelines"
        :href="goToPipelinesPath"
        class="btn btn-success"
        :data-track-property="humanAccess"
        :data-track-value="$options.goToTrackValuePipelines"
        :data-track-event="$options.trackEvent"
        :data-track-label="trackLabel"
      >
        {{ $options.pipelinesButton }}
      </a>
    </template>
  </gl-modal>
</template>
