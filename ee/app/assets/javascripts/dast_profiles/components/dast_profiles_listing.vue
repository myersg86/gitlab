<script>
export default {
  props: {
    profiles: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasProfiles() {
      return this.profiles.length > 0;
    },
  },
};
</script>
<template>
  <section class="gl-py-3">
    <ul v-if="hasProfiles" :aria-label="s__('DastLibrary|Site Profiles')">
      <li v-for="profile in profiles" :key="profile.id">
        <span>{{ profile.profileName }}</span>
        <span>{{ profile.targetUrl }}</span>
        <span>{{ profile.validationStatus }}</span>
      </li>
    </ul>
    <p v-else>{{ s__('DastProfiles|No profiles created yet') }}</p>
  </section>
</template>
