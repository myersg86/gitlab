<script>
import icon from '~/vue_shared/components/icon.vue';
import { GlButton } from '@gitlab/ui';

export default {
  title: 'Collaborate with your team',
  body: "We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge.",
  button_text: 'Invite your colleagues',
  components: {
    GlButton,
  },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    groupMembersPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="invite-wrapper">
    <div class="container-fluid container-limited limit-container-width">
      <div class="gl-pb-5"> </div>
      <div class="border gl-border-grey-100 gl-display-flex gl-pt-5">
        <div class="col-3 svg-content svg-225 flex-column">
          <img data-testid="svg-image" :src="svgPath" />
        </div>
        <div class="col-8 gl-mt-5">
          <strong>
            {{ $options.title }}
          </strong>
          <p class="gl-mt-2">
            {{ $options.body }}
          </p>
          <gl-button variant="info" class="btn gl-mt-2 btn-info btn-md gl-button" :href="groupMembersPath">
            {{ $options.button_text }}
          </gl-button>
        </div>
        <div class="col-1">
        </div>
      </div>
    </div>
  </div>
</template>
