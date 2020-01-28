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
      newNoteCoordinates: null,
      newNoteClientCoordinates: null,
      newNoteCoordinatesDelta: {},
      newNoteInitialCoordinates: null,
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
    newNotePosition() {
      const pos = this.newNoteCoordinates
        ? this.getNotePosition({ ...this.newNoteCoordinates, ...this.dimensions })
        : this.getNotePosition(this.currentCommentForm);
      // console.log('setting annotation postiion');
      // // const pos = this.getNotePosition(this.currentCommentForm);
      return pos;
    },
  },
  methods: {
    setNewNoteCoordinates(newNoteCoordinates) {
      this.newNoteCoordinates = newNoteCoordinates;
      this.newNoteInitialCoordinates = newNoteCoordinates;
      this.$emit('setAnnotationCoordinates', newNoteCoordinates);
    },
    onMousemove(e) {
      if (this.newNoteClientCoordinates) {
        const deltaX = e.clientX - this.newNoteClientCoordinates.x;
        const deltaY = e.clientY - this.newNoteClientCoordinates.y;
        const x = this.newNoteInitialCoordinates.x + deltaX;
        const y = this.newNoteInitialCoordinates.y + deltaY;

        this.newNoteCoordinates = {
          x,
          y,
        };
      }
    },
    onNewNoteMousedown(e) {
      this.newNoteClientCoordinates = { x: e.clientX, y: e.clientY };
    },
    onNewNoteMouseup() {
      this.newNoteClientCoordinates = null;
      this.setNewNoteCoordinates(this.newNoteCoordinates);
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
      @click="setNewNoteCoordinates({ x: $event.offsetX, y: $event.offsetY })"
    ></button>
    <design-comment-pin
      v-for="(note, index) in notes"
      :key="note.id"
      :index="index"
      :position="getNotePosition(note.position)"
    />
    <design-comment-pin
      v-if="currentCommentForm"
      :position="newNotePosition"
      :repositioning="Boolean(newNoteClientCoordinates)"
      @mousedown="onNewNoteMousedown"
      @mouseup="onNewNoteMouseup"
    />
  </div>
</template>
