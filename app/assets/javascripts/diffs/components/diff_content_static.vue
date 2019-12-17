<script>
import { MATCH_LINE_TYPE, CONTEXT_LINE_TYPE, CONTEXT_LINE_CLASS_NAME } from '../constants';

export default {
  name: 'DiffContentStatic',
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
    const mapLines = l => ({
      old_line: l.old_line,
      new_line: l.new_line,
      type: l.type,
      rich_text: l.rich_text,
      inlineRowId: l.line_code || `${diffFile.fileHash}_${l.old_line}_${l.new_line}`,
      classNameMap: [
        'line_holder',
        l.type,
        { [CONTEXT_LINE_CLASS_NAME]: l.type === CONTEXT_LINE_TYPE },
      ],
    });

    const oldGa = l => (l.old_line ? h('a', l.old_line) : null);
    const newGa = l => (l.new_line ? h('a', l.new_line) : null);
    const oldG = l => h('td', { class: [l.type, 'diff-line-num old_line'] }, [oldGa(l)]);
    const newG = l => h('td', { class: [l.type, 'diff-line-num new_line'] }, [newGa(l)]);
    const td = l =>
      h('td', { class: [l.type, 'line_content'], domProps: { innerHTML: l.rich_text } });
    const lines = diffFile.highlighted_diff_lines
      .filter(l => l.type !== MATCH_LINE_TYPE)
      .map(mapLines)
      .map(l => h('tr', { id: l.inlineRowId, class: l.classNameMap }, [oldG(l), newG(l), td(l)]));

    const col = h('col', { style: 'width: 50px;' });
    const colgroup = h('colgroup', [col, col]);
    const table = h(
      'table',
      {
        class: [
          'code diff-wrap-lines js-syntax-highlight text-file js-diff-inline-view',
          window.gon.user_color_scheme,
        ],
      },
      [colgroup, lines],
    );
    const diffViewer = h('div', { class: 'diff-viewer' }, [table]);
    const diffContent = h('div', { class: 'diff-content' }, [diffViewer]);
    return diffContent;
  },
};
</script>
