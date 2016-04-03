import Ember from 'ember';

export default Ember.Component.extend({

  model: Ember.computed.alias('parentView.model'),
  checkin: Ember.computed.alias('model.checkin'),

  stepControls: true,
  selectedTag: null,

  actions: {
    add(tag) {
      this.get('checkin').addTag(tag);
      this.saveCheckin();
      this.set('selectedTag', null);
    },
    remove(tag) {
      this.get('checkin').removeTag(tag);
      this.saveCheckin();
    },
    completeStep() {
      this.get('onStepCompleted')();
    },
    goBack() {
      this.get('onGoBack')();
    }
  },

  saveCheckin() {
    if (this.get('checkin.hasDirtyAttributes')) {
      Ember.run.next(this, function() {
        this.get('checkin').save().then(() => {
          Ember.Logger.debug('Checkin successfully saved');
          this.get('checkin').set('hasDirtyAttributes', false);
        }, (error) => {
          Ember.logger.error(error);
        });
      });
    } else {
      // Ember.Logger.debug("No need to save checkin");
    }
  }

});
