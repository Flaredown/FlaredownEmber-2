import Ember from 'ember';
import InViewportMixin from 'ember-in-viewport';

const {
  get,
  set,
  observer,
  Component,
  getProperties,
  run: {
    schedule,
  },
  inject: {
    service,
  },
} = Ember;

export default Component.extend(InViewportMixin, {
  init() {
    this._super(...arguments);

    const commentId = get(this, 'comment.id');

    if (commentId) {
      set(this, 'elementId', `anchor-${commentId}`);
    }
  },

  visited: false,

  ajax: service(),
  notifications: service(),

  didEnterViewport() {
    schedule('afterRender', this, this.setVisited);
  },

  setVisited() {
    set(this, 'visited', true);
  },

  destroyNotifications: observer('visited', 'comment.body', function() {
    const {
      ajax,
      comment,
      visited,
    } = getProperties(this, 'ajax', 'comment', 'visited');

    const { id, hasNotifications } = getProperties(comment, 'id', 'hasNotifications');

    if (visited && hasNotifications) {
      const store = get(this, 'store');

      ajax
        .put(`notifications/comment/${id}`)
        .then(({notifications}) => {

          notifications.forEach((n) => {
            const model = store.peekRecord('notification', n.id);

            if(model){
              set(model, 'unread', false);
            }
          });
          set(comment, 'notifications', {});
        });
    }
  }),
});
