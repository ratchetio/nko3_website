var express = require('express')
  , auth = require('mongoose-auth')
  , env = require('./env')
  , util = require('util')
  , port = env.port
  , secrets = env.secrets
  , EventEmitter = require('events').EventEmitter
  , Stats = require('../models/stats')
  , ratchetio = require('ratchetio');

// express
var app = module.exports = express.createServer();

// some paths
app.paths = {
  public: __dirname + '/../public',
  views: __dirname + '/../views'
};

// uncaught error handling
ratchetio.handleUncaughtExceptions('a99bad94e4ba4ec0b78dc90e033743b1');

var airbrake = require('airbrake').createClient('b76b10945d476da44a0eac6bfe1aeabd');
process.on('uncaughtException', function(e) {
  util.debug(e.stack.red);
  if (env.node_env === 'production')
    airbrake.notify(e);
});


// utilities & hacks
require('colors');
require('../lib/render2');
require('../lib/underscore.shuffle');
require('../lib/regexp-extensions');

// events
app.events = new EventEmitter();

// db
app.db = require('../models')(env.mongo_url);
app.db.app = app;  // sooo hacky

// stats (kinda hacky)
app.stats = new Stats(app.db, function(err) {
  if (err) throw err;
});
app.stats.on('change', function(stats) {
  app.events.emit('updateStats', stats);
});


// state (getting pretty gross)
app.disable('registration');  // months beforehand
app.disable('pre-coding');     // week beforehand
app.enable('coding');        // coding + several hours before
app.disable('voting');        // after

app.configure(function() {
  var assetManager = require('./assetmanager')(app);

  app.use(express.compress());
  app.use(assetManager);
  app.helpers({ assetManager: assetManager });
});

app.configure('development', function() {
  app.use(express.static(app.paths.public));
  require('../lib/mongo-log')(app.db.mongo);
});
app.configure('production', function() {
  app.use(express.static(app.paths.public, { maxAge: 1000*60*5 }));
  app.use(function(req, res, next) {
    if (req.connection.remoteAddress !== '127.0.0.1' && req.headers.host !== 'nodeknockout.com')
      res.redirect('http://nodeknockout.com' + req.url);
    else
      next();
  });
});

app.configure(function() {
  var RedisStore = require('connect-redis')(express);

  // cookies and sessions
  app.use(express.cookieParser());
  app.use(express.session({
    secret: secrets.session,
    store: new RedisStore,
    cookie: { path: '/', httpOnly: true, maxAge: 1000*60*60*24*28 }
  }));

  app.use(express.bodyParser());
  app.use(express.methodOverride());

  // hacky solution for post commit hooks not to check csrf
  app.use(require('../controllers/commits')(app));
  app.use(require('../controllers/deploys')(app));

  // csrf protection
  app.use(express.csrf());
  app.use(function(req, res, next) {
    if (req.body) delete req.body._csrf;
    next();
  });

  app.use(express.logger());
  app.use(auth.middleware());
  app.use(app.router);

  // request error handling
  app.use(ratchetio.errorHandler());

  app.use(function(e, req, res, next) {
    if (typeof(e) === 'number')
      return res.render2('errors/' + e, { status: e });

    if (typeof(e) === 'string')
      e = Error(e);

    if (env.node_env === 'production')
      airbrake.notify(e);

    res.render2('errors/500', { error: e });
  });

  app.set('views', app.paths.views);
  app.set('view engine', 'jade');
});

// helpers
auth.helpExpress(app);
require('../helpers')(app);

app.listen(port);
app.ws = require('socket.io').listen(app);
app.ws.set('log level', 1);
app.ws.set('browser client minification', true);

app.on('listening', function() {
  require('util').log('listening on ' + ('0.0.0.0:' + port).cyan);

  // if run as root, downgrade to the owner of this file
  if (env.production && process.getuid() === 0)
    require('fs').stat(__filename, function(err, stats) {
      if (err) return util.log(err)
      process.setuid(stats.uid);
    });
});
