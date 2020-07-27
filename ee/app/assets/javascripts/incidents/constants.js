import { s__ } from '~/locale';

const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-white-space-nowrap';

// eslint-disable-next-line import/prefer-default-export
export const publishedCell = {
  key: 'published',
  label: s__('IncidentManagement|Published'),
  thClass: 'gl-pointer-events-none',
  tdClass,
};
