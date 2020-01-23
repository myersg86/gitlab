<script>
import DesignCommentPin from './design_comment_pin.vue';

export default {
  name: 'DesignOverlay',
  components: {
    DesignCommentPin,
  },
  props: {
    dimensions: {
      type: Object,
      required: true,
    },
    position: {
      type: Object,
      required: true,
    },
    notes: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentCommentForm: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    overlayStyle() {
      return {
        width: `${this.dimensions.width}px`,
        height: `${this.dimensions.height}px`,
        ...this.position,
      };
    },
  },
  methods: {
    setAnnotationCoordinates(x, y) {
      this.$emit('setAnnotationCoordinates', { x, y });
    },
    getNotePosition(data) {
      const { x, y, width, height } = data;
      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;
      return {
        left: `${Math.round(x * widthRatio)}px`,
        top: `${Math.round(y * heightRatio)}px`,
      };
    },
    onNoteMove(notableId, coordinates) {
      this.$emit('moveNote', {
        notableId,
        coordinates,
      });
    },
  },
};
</script>

<template>
  <div class="position-absolute image-diff-overlay frame" :style="overlayStyle">
    <button
      type="button"
      class="btn-transparent position-absolute image-diff-overlay-add-comment w-100 h-100 js-add-image-diff-note-button"
      data-qa-selector="design_image_button"
      @click="setAnnotationCoordinates($event.offsetX, $event.offsetY)"
    ></button>
    <design-comment-pin
      v-for="(note, index) in notes"
      :key="note.id"
      :index="index"
      :position="getNotePosition(note.position)"
      @move="onNoteMove(note.id, $event)"
    />
    <design-comment-pin
      v-if="currentCommentForm"
      :key="note.id"
      :position="getNotePosition(currentCommentForm)"
      @move="setAnnotationCoordinates"
    />
  </div>
</template>
