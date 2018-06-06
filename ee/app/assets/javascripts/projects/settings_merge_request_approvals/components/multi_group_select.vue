<script>
import $ from 'jquery';
import GroupsSelect from '~/groups_select';

export default {
  props: {
    groups: {
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
    new GroupsSelect(); // eslint-disable-line no-new
    const select = $(this.$refs.groupSelect);
    select.on('change', e => {
      this.$emit('select', e);
    });
    select.select2('data', this.groups);
  },
};
</script>

<template>
  <input
    ref="groupSelect"
    type="hidden"
    value=""
    multiple="multiple"
    data-all-available="true"
    class="input-large ajax-groups-select multiselect multiselect"
  />
</template>
