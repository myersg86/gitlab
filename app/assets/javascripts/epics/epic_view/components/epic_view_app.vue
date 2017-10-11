<script>
  import epicHeader from './epic_header.vue';

  export default {
    name: 'epicViewApp',
    components: {
      epicHeader,
    },
    created() {
      // TODO: Get mock data from backend
      this.author = {
        url: 'test.com',
        src: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=48&d=identicon',
        username: '@root',
        name: 'Administrator',
      };
      this.created = (new Date()).toISOString();
    },
  };
</script>

<template>
  <div>
    <epic-header
      :author="author"
      :created="created"
    />
  </div>
</template>
