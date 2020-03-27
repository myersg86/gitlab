<script>
import { GlLoadingIcon } from '@gitlab/ui';
import getIconForFile from './file_icon/file_icon_map';
import icon from '../../vue_shared/components/icon.vue';

/* This is a re-usable vue component for rendering a svg sprite
    icon

    Sample configuration:

    <file-icon
      name="retry"
      :size="32"
      css-classes="top"
    />

  */
export default {
  components: {
    icon,
    GlLoadingIcon,
  },
  props: {
    fileName: {
      type: String,
      required: true,
    },
    fileMode: {
      type: String,
      required: false,
      default: '',
    },

    folder: {
      type: Boolean,
      required: false,
      default: false,
    },

    opened: {
      type: Boolean,
      required: false,
      default: false,
    },

    loading: {
      type: Boolean,
      required: false,
      default: false,
    },

    size: {
      type: Number,
      required: false,
      default: 16,
    },

    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    useSprite() {
      return !this.loading && !this.folder && this.fileMode !== '120000';
    },
    useIcon() {
      return !this.loading && (this.folder || this.fileMode === '120000');
    },
    iconName() {
      let name = this.opened ? 'folder-open' : 'folder';

      if (this.fileMode === '120000') {
        name = 'leave';
      }

      return name;
    },
    iconClasses() {
      const classes = [];

      if (this.iconName.includes('folder')) {
        classes.push('folder-icon');
      }

      return classes;
    },
    spriteHref() {
      const iconName = getIconForFile(this.fileName) || 'file';
      return `${gon.sprite_file_icons}#${iconName}`;
    },
    iconSizeClass() {
      return this.size ? `s${this.size}` : '';
    },
  },
};
</script>
<template>
  <span>
    <svg v-if="useSprite" :class="[iconSizeClass, cssClasses]">
      <use v-bind="{ 'xlink:href': spriteHref }" />
    </svg>
    <icon v-if="useIcon" :name="iconName" :size="size" :class="iconClasses" />
    <gl-loading-icon v-if="loading" :inline="true" />
  </span>
</template>
