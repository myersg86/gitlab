<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    statusPagePublishedIncident: {
      type: Boolean,
      required: false,
      default: null,
    },
    unPublished: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div data-testid="published-cell">
    <gl-icon v-if="statusPagePublishedIncident" name="status_success" class="gl-fill-green-500" />
    <div v-else>{{ unPublished }}</div>
  </div>
</template>

<!-- TODO: Replace via GitLab UI utility class -->
<style>
.gl-fill-green-500 {
  fill: #108548;
}
</style>
