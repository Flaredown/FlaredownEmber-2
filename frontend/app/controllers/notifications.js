import Ember from 'ember';
import BackNavigateable from 'flaredown/mixins/back-navigateable';
import UserNameable from 'flaredown/mixins/user-nameable';
import SearchableDropdown from 'flaredown/mixins/searchable-dropdown';
import NavbarSearchable from 'flaredown/mixins/navbar-searchable';

const {
  get,
  computed,
  Controller,
} = Ember;

export default Controller.extend(BackNavigateable, UserNameable, SearchableDropdown, NavbarSearchable, {
  title: computed('screenName', function() {
    let screenName = get(this, 'screenName');

    return `${screenName ? screenName : 'User'}'s notifications`;
  }),
});
