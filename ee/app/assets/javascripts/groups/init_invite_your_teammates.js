import Vue from 'vue';
import InviteYourTeammates from '~/groups/components/invite_your_teammates.vue';

export default function initInviteYourTeammates() {
  const el = document.querySelector('.js-invite-your-teammates');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render: (createElement) =>
      createElement(InviteYourTeammates, {
        props: {
          ...el.dataset,
        },
      }),
  });
}
