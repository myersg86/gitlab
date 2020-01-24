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
  data() {
    return {
      annotationCoordinates: null,
      annotationPinMousedown: null,
      annotationOffset: {},
      startingAnnotationCoordinates: null,
    };
  },

  computed: {
    overlayStyle() {
      return {
        width: `${this.dimensions.width}px`,
        height: `${this.dimensions.height}px`,
        ...this.position,
      };
    },
    annotationPosition() {
      const pos = this.annotationCoordinates
        ? this.getNotePosition({ ...this.annotationCoordinates, ...this.dimensions })
        : this.getNotePosition(this.currentCommentForm);
      // console.log('setting annotation postiion');
      // // const pos = this.getNotePosition(this.currentCommentForm);
      return pos;
    },
  },
  watch: {
    annotationOffset(val, prevVal) {
      if (val.x === prevVal.x && val.y === prevVal.y) return;
      const x = this.startingAnnotationCoordinates.x + val.x;
      const y = this.startingAnnotationCoordinates.y + val.y;

      this.annotationCoordinates = {
        x,
        y,
      };
    },
  },
  methods: {
    setAnnotationCoordinates(annotationCoordinates) {
      this.annotationCoordinates = annotationCoordinates;
      this.startingAnnotationCoordinates = annotationCoordinates;
      this.$emit('setAnnotationCoordinates', annotationCoordinates);
    },
    onMousemove(e) {
      if (this.annotationPinMousedown) {
        const deltaX = e.clientX - this.annotationPinMousedown.x;
        const deltaY = e.clientY - this.annotationPinMousedown.y;
        this.annotationOffset = {
          x: deltaX,
          y: deltaY,
        };
      }
    },
    onMousedown(e) {
      this.annotationPinMousedown = { x: e.clientX, y: e.clientY };
    },
    onMouseup() {
      this.annotationPinMousedown = null;
      this.startingAnnotationCoordinates = this.annotationCoordinates;
      this.$emit('setAnnotationCoordinates', this.annotationCoordinates);
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
  <div
    class="position-absolute image-diff-overlay frame"
    :style="overlayStyle"
    @mousemove="onMousemove"
  >
    <button
      type="button"
      class="btn-transparent position-absolute image-diff-overlay-add-comment w-100 h-100 js-add-image-diff-note-button"
      data-qa-selector="design_image_button"
      @click="setAnnotationCoordinates({ x: $event.offsetX, y: $event.offsetY })"
    ></button>
    <design-comment-pin
      v-for="(note, index) in notes"
      :key="note.id"
      :index="index"
      :position="getNotePosition(note.position)"
    />
    <design-comment-pin
      v-if="currentCommentForm"
      :position="annotationPosition"
      @mousedown="onMousedown"
      @mouseup="onMouseup"
    />
  </div>
</template>
