<script>

/* This is a re-usable vue component for rendering a user avatar username wrapped in
  a clickable link (likely to the user's profile). The link, image, and
  tooltip can be configured by props passed to this component.

  Sample configuration:

  <user-avatar-username-link
    :link-href="userProfileUrl"
    :img-src="userAvatarSrc"
    :img-alt="tooltipText"
    :img-size="20"
    :tooltip-text="tooltipText"
    :text="text"
  />

*/

import userAvatarImage from './user_avatar_image.vue';
import tooltip from '../../directives/tooltip';

export default {
  name: 'UserAvatarUsernameLink',
  components: {
    userAvatarImage,
  },
  props: {
    linkHref: {
      type: String,
      required: false,
      default: '',
    },
    imgSrc: {
      type: String,
      required: false,
      default: '',
    },
    imgAlt: {
      type: String,
      required: false,
      default: '',
    },
    imgCssClasses: {
      type: String,
      required: false,
      default: '',
    },
    imgSize: {
      type: Number,
      required: false,
      default: 20,
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
  directives: {
    tooltip,
  },
};
</script>

<template>
  <a
    class="user-avatar-link"
    :href="linkHref">
    <user-avatar-image
      :img-src="imgSrc"
      :img-alt="imgAlt"
      :css-classes="imgCssClasses"
      :size="imgSize"
      :tooltip-placement="tooltipPlacement"
    /><span
      class="author"
      v-tooltip
      :title="tooltipText"
      :tooltip-placement="tooltipPlacement"
    >{{text}}</span>
  </a>
</template>
