<script>
// import state from '../store/modules/diff_state';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';

export default {
  name: 'DiffFileHeaderStatic',
  functional: true,
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  render(
    h,
    {
      props: { diffFile },
    },
  ) {
    const filePath = () => {
      if (diffFile.submodule) {
        return `${diffFile.file_path} @ ${truncateSha(diffFile.blob.id)}`;
      }

      if (diffFile.deleted_file) {
        return sprintf(__('%{filePath} deleted'), { filePath: diffFile.file_path }, false);
      }

      return diffFile.file_path;
    };
    const headerContent = h('div', { class: 'file-header-content' }, filePath());
    return h('div', { ref: 'header', class: 'js-file-title file-title file-title-flex-parent' }, [
      headerContent,
    ]);
  },
};
</script>
