import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const addTimezoneIdentifier = (freezePeriod, timezoneList) =>
  convertObjectPropsToCamelCase({
    ...freezePeriod,
    cron_timezone: timezoneList.find(tz => tz.identifier === freezePeriod.cron_timezone)?.name,
  });

export default {
  addTimezoneIdentifier,
};
