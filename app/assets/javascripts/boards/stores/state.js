import { inactiveId } from '~/boards/constants';

export default () => ({
  endpoints: {},
  isShowingLabels: true,
  activeId: inactiveId,
  configurationOptions: {
    hideLabels: false,
    hideOpenList: false,
    hideClosedList: false,
  },
});
