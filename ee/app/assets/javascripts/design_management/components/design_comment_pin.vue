<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'DesignCommentPin',
  components: {
    Icon,
  },
  props: {
    position: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    inProgress() {
      return this.index !== null;
    },
  },
};
</script>

<template>
  <button
    v-if="currentCommentForm"
    :style="notePosition"
    :aria-label="__('Comment form position')"
    :class="{
      'btn-transparent comment-indicator': inProgress,
      'js-image-badge badge badge-pill': !inProgress,
    }"
    class=" position-absolute"
    type="button"
  >
    <icon v-if="inProgess" name="image-comment-dark" />
    <template v-else>
      {{ index + 1 }}
    </template>
  </button>
</template>
