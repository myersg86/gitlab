<script>
import Api from 'ee/api';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import MetricCard from '../../shared/components/metric_card.vue';
import { removeFlash } from '../utils';

const I18N_TEXT = {
  'lead-time': __('Median time from issue created to issue closed.'),
  'cycle-time': __('Median time from first commit to issue closed.'),
};

const tooltipText = key => {
  if (I18N_TEXT[key]) {
    return I18N_TEXT[key];
  }
  return '';
};

export default {
  name: 'TimeMetricsCard',
  components: {
    MetricCard,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    additionalParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      data: [],
      loading: false,
    };
  },
  watch: {
    additionalParams() {
      this.fetchData();
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      removeFlash();
      this.loading = true;
      return Api.cycleAnalyticsTimeSummaryData(this.groupPath, this.additionalParams)
        .then(({ data }) => {
          this.data = data.map(({ title: label, ...rest }) => {
            const key = slugify(label);
            return {
              ...rest,
              label,
              key,
              tooltipText: tooltipText(key),
            };
          });
        })
        .catch(() => {
          createFlash(
            __('There was an error while fetching value stream analytics time summary data.'),
          );
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
  render() {
    return this.$scopedSlots.default({
      metrics: this.data,
      loading: this.loading,
    });
  },
};
</script>
