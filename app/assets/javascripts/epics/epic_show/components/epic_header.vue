<script>
  import userAvatarUsernameLink from '../../../vue_shared/components/user_avatar/user_avatar_username_link.vue';
  import timeagoTooltip from '../../../vue_shared/components/time_ago_tooltip.vue';
  import tooltip from '../../../vue_shared/directives/tooltip';

  export default {
    name: 'epicHeader',
    props: {
      author: {
        type: Object,
        required: true,
        validator: value => value.url && value.username && value.name,
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
      userAvatarUsernameLink,
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
     <strong>
      <user-avatar-username-link
        :link-href="author.url"
        :img-src="author.src"
        :img-size="24"
        :tooltipText="author.username"
        :text="author.name"
        imgCssClasses="avatar-inline"
      />
    </strong>
  </div>
</template>
