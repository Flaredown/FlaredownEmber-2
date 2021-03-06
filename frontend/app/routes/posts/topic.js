import Ember from 'ember';
import HistoryTrackable from 'flaredown/mixins/history-trackable';
import ToggleHeaderLogo from 'flaredown/mixins/toggle-header-logo';
import AddMetaTags from 'flaredown/mixins/add-meta-tags';

const {
  get,
  set,
  inject: {
    service,
  },
  Route,
  getProperties,
  RSVP: {
    hash,
  },
} = Ember;

const availableTypes = ['tag', 'symptom', 'condition', 'treatment'];

export default Route.extend(HistoryTrackable, ToggleHeaderLogo, AddMetaTags, {
  session: service(),

  model(params) {
    const { id, type } = params;

    if (!availableTypes.includes(type)) {
      return this.transitionTo('posts');
    }

    const store = get(this, 'store');
    const currentUser = get(this, 'session.currentUser');

    return hash({
      id,
      type,
      page: 1,
      posts: store.query('post', { id, type }).then(q => q.toArray()),
      topic: store.findRecord(type, id),
      topicFollowing: currentUser ? currentUser.then(user => get(user, 'topicFollowing')) : [],
    });
  },

  historyEntry(model) {
    const { id, type } = getProperties(model, 'id', 'type');

    return this._super(...arguments).pushObjects([type, id]);
  },

  setHeadTags: function(model) {
    const currentUrl = get(this, 'currentUrl');

    const headTags = [
      { type: 'meta',
        tagId: 'title',
        attrs: {
          property: 'og:title',
          content: 'Topic',
        },
      },
      { type: 'meta',
        tagId: 'description',
        attrs: {
          property: 'og:description',
          content: get(model, 'topic.name'),
        },
      },
      { type: 'meta',
        tagId: 'url',
        attrs: {
          property: 'og:url',
          content: currentUrl,
        },
      },

      //Twitter meta tags
      { type: 'meta',
        tagId: 'card',
        attrs: {
          name: 'twitter:card',
          content: 'summary',
        },
      },
      {
        type: 'meta',
        tagId: 'googleDesc',
        attrs: {
          name: 'description',
          content: get(model, 'topic.name'),
        },
      },
    ];

    set(this, 'headTags', headTags);
  },

});
