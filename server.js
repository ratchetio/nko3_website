require('coffee-script');

[ 'login',
  'index',
  'iframe',
  'people',
  'judges',
  'teams',
  'votes',
  'websocket',
  'live',
  'redirect'
].forEach(function(controller) {
  require('./controllers/' + controller);
});

// commits and deploys are required directly in app.js
