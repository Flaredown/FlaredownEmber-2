/*jshint node:true*/
/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function(defaults) {
  var app = new EmberApp(defaults, {
    dotEnv: {
      path: {
        development: '../backend/.env',
      }
    },

    sassOptions: {
      includePaths: [
        'bower_components/spinkit/scss'
      ]
    },

    fingerprint: {
      exclude: [
        'weather/clear-day',
        'weather/clear-night',
        'weather/cloudy',
        'weather/default',
        'weather/fog',
        'weather/partly-cloudy-day',
        'weather/partly-cloudy-night',
        'weather/rain',
        'weather/sleet',
        'weather/snow',
        'weather/wind',
      ],
    },

    svg: {
      paths: [
        'public/assets/nav_icons',
      ],

      optimize: {
        plugins: [
          { removeDoctype: false },
          { removeTitle: true },
          { removeDesc: true },
        ],
      },
    },
  });

  // pace
  app.import(app.bowerDirectory + '/pace/pace.js');

  // pusher
  app.import(app.bowerDirectory + '/pusher/dist/pusher.js');

  // d3
  app.import(app.bowerDirectory + '/d3/d3.min.js');

  // MomentJS
  app.import(app.bowerDirectory + '/momentjs/moment.js');
  app.import(app.bowerDirectory + '/moment-range/dist/moment-range.js');

  // HTML5 Drag and Drop Polyfill for Mobile
  app.import(app.bowerDirectory + '/drag-drop-polyfill/release/drag-drop-polyfill.js');
  app.import(app.bowerDirectory + '/drag-drop-polyfill/release/drag-drop-polyfill-scroll-behaviour.js');
  app.import(app.bowerDirectory + '/drag-drop-polyfill/release/drag-drop-polyfill.css');
  app.import(app.bowerDirectory + '/drag-drop-polyfill/release/drag-drop-polyfill-icons.css');

  // At-js
  app.import(app.bowerDirectory + '/At.js/dist/css/jquery.atwho.css');

  return app.toTree();
};
