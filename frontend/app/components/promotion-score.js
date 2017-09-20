import Ember from 'ember';
import { translationMacro as t } from "ember-i18n";
import config from 'flaredown/config/environment';

const {
  get,
  computed,
  computed: {
    alias,
  },
  inject: {
    service,
  },
  Component,
} = Ember;

export default Component.extend({
  i18n: service(),
  _routing: service('-routing'),

  classNames: ['checkinReviewBody'],

  prScore: alias('pr.score'),

  showReviewPage: computed('prScore', function() {
    const score = get(this, 'prScore');

    return score >= 9;
  }),

  appStoreURL: config.review.appStore,
  googlePlayUrl: config.review.googlePlay,

  highRateHeader: t("step.checkin.promotion_rate.reviewHeader"),
  lowRateHeader: t("step.checkin.promotion_rate.feedBackHeader"),

  reviewHeader: computed('showReviewPage', function() {
    return get(this, 'showReviewPage') ? get(this, 'highRateHeader') : get(this, 'lowRateHeader');
  }),

  currentUrl: computed(function() {
    get(this, '_routing.router.currentURL');
  }),

  actions: {
    sendFeedback() {
      get(this, 'pr').save();
      get(this, 'onForward')();
    },

    openAppStore() {
      window.open(get(this, 'appStoreURL'));
    },

    openGooglePlay() {
      window.open(get(this, 'googlePlayUrl'));
    },
  }
});