<script>
  import userAvatarLink from '../../../vue_shared/components/user_avatar/user_avatar_link.vue';
  import timeagoTooltip from '../../../vue_shared/components/time_ago_tooltip.vue';
  import tooltip from '../../../vue_shared/directives/tooltip';

  export default {
    name: 'epicHeader',
    props: {
      author: {
        type: Object,
        required: true,
        // TODO: Add validator
      },
      created: {
        type: String,
        required: true,
      },
    },
    directives: {
      tooltip,
    },
    components: {
      userAvatarLink,
      timeagoTooltip,
    },
  };
</script>

<template>
  <div class="detail-page-header">
    Opened
    <timeagoTooltip
      :time="created"
    />
     by
    <user-avatar-link
      :link-href="author.url"
      :img-src="author.src"
      :img-size="24"
      imgCssClasses="avatar-inline"
    >
      <span
        class="author"
        v-tooltip
        :title="author.username"
      >
        {{ author.name }}
      </span>
    </user-avatar-link>
  </div>
</template>
