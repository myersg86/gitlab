<script>
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('SecurityDashboard|Security Dashboard'),
  },
};
</script>

<template functional>
  <div>
    <h1>{{ $options.i18n.title }}</h1>
    <div class="security-charts gl-display-flex gl-flex-wrap">
      <slot></slot>
    </div>
  </div>
</template>

<style>
.security-charts > * {
  flex: 1 1 40%;
  margin: 1rem;
}
</style>
