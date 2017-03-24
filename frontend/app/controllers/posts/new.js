import Ember from 'ember';
import SearchableDropdown from 'flaredown/mixins/searchable-dropdown';

const {
  get,
  computed,
  Controller,
  getProperties,
} = Ember;

export default Controller.extend(SearchableDropdown, {
  disabled: computed('model.body', 'model.title', 'model.topics.[]', function() {
    const { body, title, topics } = getProperties(get(this, 'model'), 'body', 'title', 'topics');

    return !(body && title && topics.length);
  }),

  randomTrackables: computed(function() {
    return this.randomSearch('topic');
  }),

  performSearch(term, resolve, reject) {
    this
      .searchByTerm('topic', term)
      .then(function() { resolve(...arguments); }, reject);
  },

  actions: {
    addTopic(topic) {
      get(this, 'model').addTopic(topic);
    },

    savePost() {
      get(this, 'model').save();
    },

    removeTopic(topic) {
      get(this, 'model').removeTopic(topic);
    },
  },
});
