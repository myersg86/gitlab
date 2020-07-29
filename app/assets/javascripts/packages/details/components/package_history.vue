<script>
import { GlLink, GlSprintf } from '@gitlab/ui';

import { s__ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';
import HistoryElement from './history_element.vue';

export default {
  name: 'PackageActivity',
  components: {
    GlLink,
    GlSprintf,
    HistoryElement,
  },
  mixins: [timeagoMixin],
  props: {
    packageEntity: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    projectName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showDescription: false,
    };
  },
  computed: {
    packagePipeline() {
      return this.packageEntity.pipeline?.id ? this.packageEntity.pipeline : null;
    },
    createdTime() {
      return this.formatTime(this.packageEntity.created_at);
    },
    createdDate() {
      return this.formatDate(this.packageEntity.created_at);
    },
    updatedTime() {
      return this.formatTime(this.packageEntity.updated_at);
    },
    updatedDate() {
      return this.formatDate(this.packageEntity.updated_at);
    },
    pipelineTime() {
      return this.formatTime(this.packagePipeline?.created_at);
    },
    pipelineDate() {
      return this.formatDate(this.packagePipeline?.created_at);
    },
  },
  methods: {
    formatTime(date) {
      return formatDate(date, 'HH:MM Z');
    },
    formatDate(date) {
      return formatDate(date, 'mmm dd, yyyy');
    },
  },
  i18n: {
    createOnText: s__(
      'PackageRegistry|%{name} version %{version} was created on %{date} at %{time}',
    ),
    updatedAtText: s__(
      'PackageRegistry|%{name} version %{version} was updated at %{date} at %{time}',
    ),
    commitText: s__('PackageRegistry|Commit %{link} on branch %{branch}'),
    pipelineText: s__(
      'PackageRegistry|Pipeline %{link} triggered on %{date} at %{time} by %{author}',
    ),
    publishText: s__(
      'PackageRegistry|Published to the %{project} Package Registry on %{date} at %{time}',
    ),
  },
};
</script>

<template>
  <div class="issuable-discussion">
    <h3 class="gl-ml-6">{{ __('History') }}</h3>
    <ul class="timeline main-notes-list notes gl-my-4">
      <history-element icon="clock">
        <gl-sprintf :message="$options.i18n.createOnText">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #date>
            {{ createdDate }}
          </template>
          <template #time>
            {{ createdTime }}
          </template>
        </gl-sprintf>
      </history-element>
      <history-element icon="pencil">
        <gl-sprintf :message="$options.i18n.updatedAtText">
          <template #name>
            <strong>{{ packageEntity.name }}</strong>
          </template>
          <template #version>
            <strong>{{ packageEntity.version }}</strong>
          </template>
          <template #date>
            {{ updatedDate }}
          </template>
          <template #time>
            {{ updatedTime }}
          </template>
        </gl-sprintf>
      </history-element>
      <template v-if="packagePipeline">
        <history-element icon="commit">
          <gl-sprintf :message="$options.i18n.commitText">
            <template #link>
              <gl-link :href="`../../commit/${packagePipeline.sha}`">
                {{ packagePipeline.sha }}
              </gl-link>
            </template>
            <template #branch>
              <strong>{{ packagePipeline.ref }}</strong>
            </template>
          </gl-sprintf>
        </history-element>
        <history-element icon="pipeline">
          <gl-sprintf :message="$options.i18n.pipelineText">
            <template #link>
              <gl-link :href="`../../pipelines/${packagePipeline.id}`">
                #{{ packagePipeline.id }}
              </gl-link>
            </template>
            <template #date>
              {{ pipelineDate }}
            </template>
            <template #time>
              {{ pipelineTime }}
            </template>
            <template #author>
              {{ packagePipeline.user.name }}
            </template>
          </gl-sprintf>
        </history-element>
      </template>
      <history-element icon="package">
        <gl-sprintf :message="$options.i18n.publishText">
          <template #project>
            <strong>{{ projectName }}</strong>
          </template>
          <template #date>
            {{ createdDate }}
          </template>
          <template #time>
            {{ createdTime }}
          </template>
        </gl-sprintf>
      </history-element>
    </ul>
  </div>
</template>
