<script>
import $ from 'jquery';
import UsersSelect from '~/users_select';

export default {
  props: {
    users: {
      type: Array,
      required: true,
    },
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  mounted() {
    new UsersSelect(); // eslint-disable-line no-new
    const select = $(this.$refs.userSelect);
    select.on('change', e => {
      this.$emit('select', e);
    });
    select.select2('data', this.users);
  },
};
</script>

<template>
  <input
    ref="userSelect"
    type="hidden"
    value=""
    class="ajax-users-select multiselect input-large "
    data-placeholder="Search for a user"
    data-null-user="false"
    data-any-user="false"
    data-email-user="true"
    data-first-user="false"
    data-current-user="false"
    :data-project-id="projectId"
  />
</template>
