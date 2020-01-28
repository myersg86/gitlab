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
      newNoteInitialCoordinates: null,
      newNoteClientCoordinates: null,
      noteCoordinates: null,
      noteClientCoordinates: null,
      movingNotePosition: null,
      movingNoteId: null,
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

      return pos;
    },
  },
  methods: {
    setNewNoteCoordinates(newNoteCoordinates) {
      this.newNoteCoordinates = newNoteCoordinates;
      this.newNoteInitialCoordinates = newNoteCoordinates;
      this.$emit('setAnnotationCoordinates', newNoteCoordinates);
    },
    findNotePosition(noteId) {
      return (this.notes.find(({ id }) => id === noteId) || {}).position;
    },
    isMovingNote(noteId) {
      return this.movingNoteId === noteId;
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
        return;
      }

      if (this.movingNoteId) {
        const notePosition = this.findNotePosition(this.movingNoteId);
        const { width, height } = notePosition;
        const widthRatio = this.dimensions.width / width;
        const heightRatio = this.dimensions.height / height;

        const deltaX = e.clientX - this.noteClientCoordinates.x;
        const deltaY = e.clientY - this.noteClientCoordinates.y;

        const x = notePosition.x * widthRatio + deltaX;
        const y = notePosition.y * heightRatio + deltaY;

        this.movingNotePosition = {
          x,
          y,
          width: this.dimensions.width,
          height: this.dimensions.height,
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
    onNoteMousedown(noteId, e) {
      this.movingNoteId = noteId;
      this.noteClientCoordinates = { x: e.clientX, y: e.clientY };
    },
    onNoteMouseup() {
      this.noteClientCoordinates = null;
      this.movingNoteId = null;
      this.movingNotePosition = null;
      // this.$emit('setAnnotationCoordinates', this.noteCoordinates);
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
      :repositioning="isMovingNote(note.id)"
      :position="
        isMovingNote(note.id) && movingNotePosition
          ? getNotePosition(movingNotePosition)
          : getNotePosition(note.position)
      "
      @mousedown="onNoteMousedown(note.id, $event)"
      @mouseup="onNoteMouseup(note.id, $event)"
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
