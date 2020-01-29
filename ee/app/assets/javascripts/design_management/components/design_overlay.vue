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
      newNotePosition: null,
      movingNotePosition: null,
      movingNote: null,
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
    newNotePositionStyle() {
      const pos = this.newNotePosition
        ? this.getNotePositionStyle(this.newNotePosition)
        : this.getNotePositionStyle(this.currentCommentForm);

      return pos;
    },
  },
  watch: {
    currentCommentForm() {
      this.movingNotePosition = null;
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
      return this.movingNote?.noteId === noteId;
    },
    onNewNoteMove(e) {
      const { initClientX, initClientY } = this.movingNote;
      const deltaX = e.clientX - initClientX;
      const deltaY = e.clientY - initClientY;

      const x = this.currentCommentForm.x + deltaX;
      const y = this.currentCommentForm.y + deltaY;

      this.newNotePosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };
    },
    onExistingNoteMove(e) {
      const notePosition = this.findNotePosition(this.movingNote.noteId);
      const { width, height } = notePosition;

      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;

      const { initClientX, initClientY } = this.movingNote;
      const deltaX = e.clientX - initClientX;
      const deltaY = e.clientY - initClientY;

      const x = notePosition.x * widthRatio + deltaX;
      const y = notePosition.y * heightRatio + deltaY;

      this.movingNotePosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };
    },
    onMousemove(e) {
      if (!this.movingNote) return;

      const { noteId } = this.movingNote;
      if (!noteId) {
        this.onNewNoteMove(e);
      } else {
        this.onExistingNoteMove(e);
      }
    },
    onNoteMousedown(e, note = {}) {
      this.movingNote = {
        noteableId: note.id,
        discussionId: note.discussion?.id,
        initClientX: e.clientX,
        initClientY: e.clientY,
      };
    },
    onNoteMouseup() {
      this.movingNote = null;
    },
    onNewNoteMouseup() {
      this.onNoteMouseup();

      const { x, y } = this.newNotePosition;
      this.setNewNoteCoordinates({ x, y });

      this.newNotePosition = null;
    },
    onExistingNoteMouseup() {
      this.onNoteMouseup();

      const { x, y } = this.movingNotePosition;
      this.$emit('moveNote', {
        discussionId: this.movingNote.discussionId,
        notableId: this.movingNote.noteId,
        coordinates: { x, y },
      });

      this.movingNotePosition = null;
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
        isMovingNote(note.id) && movingNotePosition
          ? getNotePositionStyle(movingNotePosition)
          : getNotePositionStyle(note.position)
      "
      @mousedown="onNoteMousedown($event, note)"
      @mouseup="onExistingNoteMouseup($event, note.id)"
    />
    <design-comment-pin
      v-if="currentCommentForm"
      :position="newNotePositionStyle"
      :repositioning="Boolean(newNotePosition)"
      @mousedown="onNoteMousedown"
      @mouseup="onNewNoteMouseup"
    />
  </div>
</template>
