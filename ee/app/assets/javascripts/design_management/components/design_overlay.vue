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
      movingNoteNewPosition: null,
      movingNoteStartPosition: null,
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
    isMovingCurrentComment() {
      return this.movingNoteStartPosition && !this.movingNoteStartPosition.noteId;
    },
    currentCommentPositionStyle() {
      const pos =
        this.movingNoteNewPosition && this.isMovingCurrentComment
          ? this.getNotePositionStyle(this.movingNoteNewPosition)
          : this.getNotePositionStyle(this.currentCommentForm);

      return pos;
    },
  },
  watch: {
    currentCommentForm() {
      // ensure currentCurrentForm is the source of truth
      this.movingNoteNewPosition = null;
    },
  },
  methods: {
    setNewNoteCoordinates(newNoteCoordinates) {
      this.$emit('setAnnotationCoordinates', newNoteCoordinates);
    },
    findNotePosition(noteId) {
      return (this.notes.find(({ id }) => id === noteId) || {}).position;
    },
    isMovingNote(noteId) {
      return this.movingNoteStartPosition?.noteId === noteId;
    },
    getMovingNotePositionDelta(e) {
      let deltaX = 0;
      let deltaY = 0;

      if (this.movingNoteStartPosition && this.movingNoteNewPosition) {
        const { initClientX, initClientY } = this.movingNoteStartPosition;
        deltaX = e.clientX - initClientX;
        deltaY = e.clientY - initClientY;
      }

      return {
        deltaX,
        deltaY,
      };
    },
    onNewNoteMove(e) {
      const { deltaX, deltaY } = this.getMovingNotePositionDelta(e);
      const x = this.currentCommentForm.x + deltaX;
      const y = this.currentCommentForm.y + deltaY;

      this.movingNoteNewPosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };
    },
    onExistingNoteMove(e) {
      const notePosition = this.findNotePosition(this.movingNoteStartPosition.noteId);
      const { width, height } = notePosition;

      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;

      const { deltaX, deltaY } = this.getMovingNotePositionDelta(e);
      const x = notePosition.x * widthRatio + deltaX;
      const y = notePosition.y * heightRatio + deltaY;

      this.movingNoteNewPosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };
    },
    onNewNoteMouseup() {
      const { x, y } = this.movingNoteNewPosition;
      this.setNewNoteCoordinates({ x, y });

      this.onNoteMouseup();
    },
    onExistingNoteMouseup() {
      const { x, y } = this.movingNoteNewPosition;
      this.$emit('moveNote', {
        noteId: this.movingNoteStartPosition.noteId,
        coordinates: { x, y },
      });

      this.onNoteMouseup();
    },
    onMousemove(e) {
      if (!this.movingNoteStartPosition) return;

      if (this.isMovingCurrentComment) {
        this.onNewNoteMove(e);
      } else {
        this.onExistingNoteMove(e);
      }
    },
    onNoteMousedown(e, note = {}) {
      this.movingNoteStartPosition = {
        noteId: note.id,
        initClientX: e.clientX,
        initClientY: e.clientY,
      };
    },
    onNoteMouseup() {
      this.movingNoteStartPosition = null;
      this.movingNoteNewPosition = null;
    },
    getNotePositionStyle(data) {
      const { x, y, width, height } = data;

      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;
      return {
        left: `${Math.round(x * widthRatio)}px`,
        top: `${Math.round(y * heightRatio)}px`,
      };
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
        isMovingNote(note.id) && movingNoteNewPosition
          ? getNotePositionStyle(movingNoteNewPosition)
          : getNotePositionStyle(note.position)
      "
      @mousedown="onNoteMousedown($event, note)"
      @mouseup="onExistingNoteMouseup($event, note.id)"
    />
    <design-comment-pin
      v-if="currentCommentForm"
      :position="currentCommentPositionStyle"
      :repositioning="isMovingCurrentComment"
      @mousedown="onNoteMousedown"
      @mouseup="onNewNoteMouseup"
    />
  </div>
</template>
