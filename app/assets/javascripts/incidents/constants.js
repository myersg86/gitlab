import { s__, __ } from '~/locale';

export const I18N = {
  errorMsg: s__('IncidentManagement|There was an error displaying the incidents.'),
  noIncidents: s__('IncidentManagement|No incidents to display.'),
  unassigned: s__('IncidentManagement|Unassigned'),
  createIncidentBtnLabel: s__('IncidentManagement|Create incident'),
  searchPlaceholder: __('Search or filter results...'),
};

export const INCIDENT_STATUS_TABS = [
  {
    title: s__('IncidentManagement|Open'),
    status: 'OPENED',
    filters: 'opened',
  },
  {
    title: s__('IncidentManagement|Closed'),
    status: 'CLOSED',
    filters: 'closed',
  },
  {
    title: s__('IncidentManagement|All incidents'),
    status: 'ALL',
    filters: 'all',
  },
];
