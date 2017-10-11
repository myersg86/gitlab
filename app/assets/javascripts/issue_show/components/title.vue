<script>
  import animateMixin from '../mixins/animate';
  import eventHub from '../event_hub';

  export default {
    mixins: [animateMixin],
    data() {
      return {
        preAnimation: false,
        pulseAnimation: false,
        titleEl: document.querySelector('title'),
      };
    },
    props: {
      issuableRef: {
        type: String,
        required: true,
      },
      titleHtml: {
        type: String,
        required: true,
      },
      titleText: {
        type: String,
        required: true,
      },
    },
    watch: {
      titleHtml() {
        this.setPageTitle();
        this.animateChange();
      },
    },
    methods: {
      setPageTitle() {
        const currentPageTitleScope = this.titleEl.innerText.split('·');
        currentPageTitleScope[0] = `${this.titleText} (${this.issuableRef}) `;
        this.titleEl.textContent = currentPageTitleScope.join('·');
      },
      edit() {
        eventHub.$emit('open.form');
      },
    },
  };
</script>

<template>
  <div class="title-container">
    <h2
      class="title"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation
      }"
      v-html="titleHtml"
    >
    </h2>
    <button
      type="button"
      class="btn-svg btn-edit"
      @click="edit"
      >
        <!-- TODO: Use gitlab svg -->
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="M13.02 1.293l1.414 1.414a1 1 0 0 1 0 1.414L4.119 14.436a1 1 0 0 1-.704.293l-2.407.008L1 12.316a1 1 0 0 1 .293-.71L11.605 1.292a1 1 0 0 1 1.414 0zm-1.416 1.415l-.707.707L12.31 4.83l.707-.707-1.414-1.415zM3.411 13.73l1.123-1.122H3.12v-1.415L2 12.312l.005 1.422 1.406-.005z"/></svg>
    </button>
  </div>
</template>
