<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  computed: {
    ...mapState('threatMonitoring', ['environments', 'currentEnvironmentId']),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName', 'canChangeEnvironment']),
  },
  methods: {
    ...mapActions('threatMonitoring', ['setCurrentEnvironmentId']),
  },
  environmentFilterId: 'threat-monitoring-environment-filter',
};
</script>

<template>
  <gl-form-group
    :label="s__('ThreatMonitoring|Environment')"
    label-size="sm"
    :label-for="$options.environmentFilterId"
    class="col-sm-6 col-md-4 col-lg-3 col-xl-2"
  >
    <gl-dropdown
      :id="$options.environmentFilterId"
      ref="environmentsDropdown"
      class="mb-0 d-flex"
      toggle-class="d-flex justify-content-between text-truncate"
      :text="currentEnvironmentName"
      :disabled="!canChangeEnvironment"
    >
      <gl-dropdown-item
        v-for="environment in environments"
        :key="environment.id"
        ref="environmentsDropdownItem"
        @click="setCurrentEnvironmentId(environment.id)"
        >{{ environment.name }}</gl-dropdown-item
      >
    </gl-dropdown>
  </gl-form-group>
</template>
