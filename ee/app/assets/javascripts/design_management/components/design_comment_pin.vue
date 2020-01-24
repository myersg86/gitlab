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
      return this.index === null;
    },
  },
};
</script>

<template>
  <button
    :style="position"
    :aria-label="__('Comment form position')"
    :class="{
      'btn-transparent comment-indicator': inProgress,
      'js-image-badge badge badge-pill': !inProgress,
    }"
    class=" position-absolute"
    type="button"
    @mousedown="$emit('mousedown', $event)"
    @mouseup="$emit('mouseup', $event)"
    @click="$emit('click', $event)"
  >
    <icon v-if="inProgress" name="image-comment-dark" />
    <template v-else>
      {{ index + 1 }}
    </template>
  </button>
</template>
