var express = require('express')
  , auth = require('mongoose-auth')
  , env = require('./env')
  , util = require('util')
  , port = env.port
  , secrets = env.secrets
  , EventEmitter = require('events').EventEmitter
  , commits = require('./../controllers/commits');

// express
var app = module.exports = express.createServer();

// some paths
app.paths = {
  public: __dirname + '/../public',
  views: __dirname + '/../views'
};

// error handling
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

// state (getting pretty gross)
app.disable('registration');  // months beforehand
app.enable('pre-coding');     // week beforehand
app.disable('coding');        // coding + several hours before
app.disable('voting');        // after

app.configure(function() {
  var coffee = require('coffee-script')
    , stylus = require('stylus');

  var assetManager = require('connect-assetmanager')({
    js: {
      route: /\/javascripts\/all-[a-z0-9]+\.js/,
      path: __dirname + '/../public/javascripts/',
      dataType: 'javascript',
      debug: env.node_env === 'development',
      preManipulate: {
        '^': [
          function(src, path, index, isLast, callback) {
            callback(src.replace(/#socketIoPort#/g, env.port));
          }
          , function(src, path, index, isLast, callback) {
            if (/\.coffee$/.test(path)) {
              callback(coffee.compile(src));
            } else {
              callback(src);
            }
          }
        ]
      },
      files: [ // order matters here
        'polyfills.js',
        'vendor/hoptoad-notifier.js',
        'vendor/hoptoad-key.js',
        'vendor/json2.js',
        'vendor/jquery-1.7.2.js',
        'vendor/jquery.ba-hashchange.js',
        'vendor/jquery.border-image.js',
        'vendor/jquery.infinitescroll.js',
        'vendor/jquery.keylisten.js',
        'vendor/jquery.pjax.js',
        'vendor/jquery.transform.light.js',
        'vendor/jquery.transloadit2.js',
        'vendor/md5.js',
        'vendor/moment.js',
        'vendor/underscore-1.3.3.js',
        'watchmaker.js',
        'application.coffee',
        '*'
      ]
    },
    css: {
      route: /\/stylesheets\/all-[a-z0-9]+\.css/,
      path: __dirname + '/../public/stylesheets/',
      dataType: 'css',
      debug: env.node_env === 'development',
      preManipulate: {
        '^': [
          function(src, path, index, isLast, callback) {
            if (/\.styl$/.test(path)) {
              stylus(src)
                .set('compress', false)
                .set('filename', path)
                .set('paths', [ __dirname, app.paths.public ])
                .render(function(err, css) {
                  callback(err || css);
                });
            } else {
              callback(src);
            }
          }
        ]
      },
      files: [ // order matters here
        'vendor/normalize.css',
        'fontello.css',
        'application.styl'
      ]
    }
  });

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
    if (req.headers.host !== 'nodeknockout.com')
      res.redirect('http://nodeknockout.com' + req.url);
    else
      next();
  });
});

app.configure(function() {
  var RedisStore = require('connect-redis')(express);

  app.use(express.cookieParser());
  app.use(express.session({
    secret: secrets.session,
    store: new RedisStore,
    cookie: { path: '/', httpOnly: true, maxAge: 1000*60*60*24*28 }
  }));
  app.use(express.bodyParser());
  app.use(express.methodOverride());

  // hacky solution for post commit hooks not to check csrf
  // app.use(commits(app));

  app.use(express.csrf());
  app.use(function(req, res, next) { if (req.body) delete req.body._csrf; next(); });
  app.use(express.logger());
  app.use(auth.middleware());
  app.use(app.router);
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
