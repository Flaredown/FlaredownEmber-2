import Ember from 'ember';

const {
  get,
  set,
  inject,
  Service,
  observer,
} = Ember;

export default Service.extend({
  store: inject.service(),
  payload: {},
  visibilityFilter: {},
  visibleChartsCount: 0,

  observeVisibilityChanges: observer(
    'payload.symptoms.@each.visible',
    'payload.conditions.@each.visible',
    'payload.treatments.@each.visible',
    'payload.weathersMesures.@each.visible',
    function() {
      const payload = get(this, 'payload');

      let count = 0;
      let filter = {};

      Object
        .keys(payload)
        .forEach(category => {
          let categoryCharts = payload[category];

          filter[category] = {};

          Object
            .keys(categoryCharts)
            .forEach(chart => {
              if (categoryCharts[chart].visible) {
                count += 1;

                filter[category][categoryCharts[chart].label] = true;
              }
            });
        });

      set(this, 'visibilityFilter', filter);
      set(this, 'visibleChartsCount', count);

      this.updateStorage();
    }
  ),

  init() {
    this._super(...arguments);

    let payload = this.getFromStorage();

    if (payload) {
      set(this, 'payload', payload);

      this.observeVisibilityChanges();
    } else {
      this.refresh();
    }
  },

  getFromStorage() {
    return localStorage.chartsVisibility && JSON.parse(localStorage.chartsVisibility);
  },

  updateStorage() {
    localStorage.chartsVisibility = JSON.stringify(get(this, 'payload'));
  },

  refresh() {
    get(this, 'store')
      .queryRecord('chart-list', {})
      .then(responce => {
        let payload = this.mergeChartsVisibility(get(responce, 'payload'), this.getFromStorage() || {});

        set(this, 'payload', payload);

        this.updateStorage();
      });
  },

  mergeChartsVisibility(allowedCharts, savedChartsVisibility) {
    let result = {};

    Object
      .keys(allowedCharts)
      .forEach(category => {
        result[category] = [];

        allowedCharts[category].forEach(chart => {
          let savedCategory = savedChartsVisibility[category];
          let chartWasPresent = savedCategory && savedCategory.findBy('label', chart);

          result[category].pushObject({
            label: chart,
            visible: !chartWasPresent || chartWasPresent.visible,
          });
        });
      });

    result.weathersMesures = [
      { label: 'Avg daily humidity', visible: true },
      { label: 'Avg daily atmospheric pressure', visible: true },
    ];

    return result;
  },
});
