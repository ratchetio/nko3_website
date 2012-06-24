var nko = {};
(function(nko) {
  //// Vector
  nko.Vector = function(x, y) {
    if (typeof(x) === 'undefined') return
    if (typeof(x) === 'number') {
      this.x = x || 0;
      this.y = y || 0;
    } else if (x.left) {
      this.x = x.left;
      this.y = x.top;
    } else {
      this.x = x.x;
      this.y = x.y;
    }
  };
  nko.Vector.prototype = {
    constructor: nko.Vector,

    plus: function(other) {
      return new this.constructor(this.x + other.x, this.y + other.y);
    },

    minus: function(other) {
      return new this.constructor(this.x - other.x, this.y - other.y);
    },

    times: function(s) {
      return new this.constructor(this.x * s, this.y * s);
    },

    length: function() {
      return Math.sqrt(Math.pow(this.x, 2) + Math.pow(this.y, 2));
    },

    toString: function() {
      return this.x + 'px, ' + this.y + 'px';
    },

    cardinalDirection: function() {
      if (Math.abs(this.x) > Math.abs(this.y))
        return this.x < 0 ? 'w' : 'e';
      else
        return this.y < 0 ? 'n' : 's';
    }
  };


  //// Thing
  nko.Thing = function(options) {
    if (!options) return;

    var self = this
      , options = options || {};

    this.name = options.name;
    this.pos = new nko.Vector(options.pos);
    this.size = new nko.Vector(options.size);
    this.ready = options.ready;

    this.div = $('<div class="thing">').addClass(this.name);
    this.img = $('<img>', { src: '/images/734m/' + this.name + '.png' })
      .load(function() {
        self.size = new nko.Vector(this.width, this.height);
        self.draw();
      });
  };

  nko.Thing.prototype.getPosition = function() {
    return this.pos.plus(this.origin);
  };

  nko.Thing.prototype.toJSON = function() {
    return {
      name: this.name,
      pos: this.pos,
      size: this.size,
      origin: this.origin
    };
  };

  nko.Thing.prototype.resetOrigin = function() {
    this.origin = new nko.Vector(this.div.offsetParent().offset());
  };

  nko.Thing.prototype.draw = function draw() {
    var offset = new nko.Vector(this.size.x * -0.5, -this.size.y + 20);
    this.div
      .css({
        left: this.pos.x,
        top: this.pos.y,
        width: this.size.x,
        height: this.size.y,
        'z-index': Math.floor(this.pos.y),
        transform: Modernizr.csstransforms ? 'translate(' + offset.toString() + ')' : null,
        background: 'url(' + this.img.attr('src') + ')'
      })
      .appendTo($('#page'));
    this.resetOrigin();
    if (this.ready) this.ready();

    this.animate();

    return this;
  };

  nko.Thing.prototype.animate = function() { };

  nko.Thing.prototype.remove = function() {
    this.div.fadeOut(function() { $(this).remove(); });
  };


  //// Dude
  nko.Dude = function(options) {
    nko.Thing.call(this, options);

    this.state = 'idle';
    this.frame = 0;
    this.bubbleFrame = 0;
  };
  nko.Dude.prototype = new nko.Thing();
  nko.Dude.prototype.constructor = nko.Dude;

  nko.Dude.prototype.draw = function draw() {
    this.idleFrames = (this.size.x - 640) / 80;
    this.size.x = 80;

    this.bubble = $('<div class="bubble">')
      .css('bottom', this.size.y + 10)
      .appendTo(this.div);

    return nko.Thing.prototype.draw.call(this);
  };

  nko.Dude.prototype.frameOffset = { w: 0, e: 2, s: 4, n: 6, idle: 8 };
  nko.Dude.prototype.animate = function animate(state) {
    var self = this;

    clearTimeout(this.animateTimeout);
    if (state) this.state = state;

    var frames = this.state === 'idle' ? this.idleFrames : 2;
    this.frame = ((this.frame + 1) % frames);
    this.div.css('background-position', (-(this.frameOffset[this.state]+this.frame) * this.size.x) + 'px 0px');

    if (this.bubble && this.bubble.is(':visible')) {
      this.bubbleFrame = (this.bubbleFrame + 1) % nko.Bubble.length;
      var src = 'data:image/png;base64,' + nko.Bubble[this.bubbleFrame];
      self.bubble.css('border-image', "url('" + src + "') 21 20 42 21");
    }

    this.animateTimeout = setTimeout(function() { self.animate() }, 400);
  };

  nko.Dude.prototype.goTo = function(pos, duration) {
    pos = new nko.Vector(pos).minus(this.origin);

    var self = this
      , delta = pos.minus(this.pos)
      , duration = arguments.length > 1 ? duration : delta.length() / 200 * 1000;
    this.animate(delta.cardinalDirection());
    if (duration && duration > 0)
      this.div.stop();
    this.div
      .animate({
        left: pos.x,
        top: pos.y
      }, {
        duration: duration,
        easing: 'linear',
        step: function(now, fx) {
          switch (fx.prop) {
            case 'left':
              self.pos.x = now;
              break;
            case 'top':
              self.pos.y = now;
              self.div.css('z-index', Math.floor(now));
              break;
          }
        },
        complete: function() {
          self.pos = pos;
          // z-index?
          self.animate('idle');
        }
      });
  };

  nko.Dude.prototype.warp = function(pos) {
    var self = this;

    this.div
      .stop()
      .fadeToggle(function() {
        self.goTo(pos, 0);
        self.div.fadeToggle();
      });
  };

  nko.Dude.prototype.speak = function(text) {
    if (!text)
      this.bubble.fadeOut();
    else
      this.bubble
        .text(text)
        .scrollTop(this.bubble.prop("scrollHeight"))
        .fadeIn();
  };


  $(function() {

    //// a dude
    var types = [ 'suit', 'littleguy', 'beast', 'gifter' ];
    var me = nko.me = new nko.Dude({
      name: types[Math.floor(types.length * Math.random())],
      pos: new nko.Vector(-100, -100),
      ready: function() {
        this.speak('type to chat. click to move around.');
        speakTimeout = setTimeout(function() { me.speak(''); }, 5000);
      }
    });

    // random dude placement
    $(window).load(function() {
      var el = $(location.hash)
      if (el.length === 0) el = $('body');
      nko.warpTo(el);
    });


    //// networking
    var dudes = nko.dudes = {};
    var ws = nko.ws = io.connect(null, {
      'port': '#socketIoPort#'
    });
    ws.on('connect', function() {
      (function heartbeat() {
        nko.send({ obj: me }, true);
        setTimeout(heartbeat, 5000);
      })();
    });
    ws.on('message', function(data) {
      var dude = dudes[data.id];

      if (data.disconnect && dude) {
        dude.remove();
        delete dudes[data.id];
      }

      if (data.obj && !dude && data.obj.pos.x < 10000 && data.obj.pos.y < 10000)
        dude = dudes[data.id] = new nko.Dude(data.obj).draw();

      if (dude && data.method) {
        dude.origin = data.obj.origin;
        nko.Dude.prototype[data.method].apply(dude, data.arguments);
      }
    });


    //// helper methods
    function randomPositionOn(selector) {
      var page = $(selector)
        , pos = page.position()

      return new nko.Vector(pos.left + 20 + Math.random() * (page.width()-40),
                            pos.top + 20 + Math.random() * (page.height()-40));
    }

    nko.warpTo = function warpTo(selector) {
      var page = $(selector)
        , pos = page.position();

      pos = randomPositionOn(page);

      me.warp(pos);
      nko.send({
        obj: me,
        method: 'warp',
        arguments: [ pos ]
      });
    }
    nko.goTo = function goTo(selector) {
      var page = $(selector)
        , pos = page.position();

      pos = randomPositionOn(page);

      me.goTo(pos);
      nko.send({
        obj: me,
        method: 'goTo',
        arguments: [ pos ]
      });

      page.click();
    };
    nko.send = function send(data, heartbeat) {
      if (!ws) return;
      var now = Date.now();

      if (now - ws.lastSentAt < 10) return; //throw Error('throttled');
      ws.lastSentAt = now;

      if (!heartbeat || ws.lastActionAt)
        ws.json.send(data);

      // disconnect after 5 minutes of idling; refresh after 2 hours
      if (now - ws.lastActionAt > 300000) ws.disconnect();
      if (now - ws.lastActionAt > 7200000) location.reload();
      if (!heartbeat) ws.lastActionAt = now;
    };


    //// event listeners

    // enter watchmaker land
    $('.thing.streetlamp').live('click touchend', function() {
      $('#inner').fadeToggle()
    });

    // movement
    var resizeTimeout = null;
    $(window)
      .resize(function(e) {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(function() { me.resetOrigin(); }, 50);
      })
      .click(function(e) { // move on click
        var pos = { x: e.pageX, y: e.pageY };
        me.goTo(pos);
        nko.send({
          obj: me,
          method: 'goTo',
          arguments: [ pos ]
        });
      })
      .keydown(function(e) {
        return true;
        if ($(e.target).is('input')) return true;
        if (e.altKey) return true;
        var d = (function() {
          switch (e.keyCode) {
            case 37: // left
              return new nko.Vector(-5000, 0);
            case 38: // up
              return new nko.Vector(0, -5000);
            case 39: // right
              return new nko.Vector(+5000, 0);
            case 40: // down
              return new nko.Vector(0, +5000);
          }
        })();
        if (d) {
          if (me.keyNav) return false;
          var pos = me.getPosition().plus(d);
          me.goTo(pos);
          nko.send({
            obj: me,
            method: 'goTo',
            arguments: [ pos ]
          });
          me.keyNav = true;
          return false;
        }
      })
      .keyup(function(e) {
        return true;
        if ($(e.target).is('input')) return true;
        if (e.altKey) return true;
        switch (e.keyCode) {
          case 37: // left
          case 38: // up
          case 39: // right
          case 40: // down
            me.goTo(me.getPosition(), 1);
            nko.send({
              obj: me,
              method: 'goTo',
              arguments: [ me.getPosition(), 1 ]
            });
            me.keyNav = false;
            return false;
        }
      });

    // ios
    var moved = false;
    $('body')
      .bind('touchmove', function(e) { moved = true; })
      .bind('touchend', function(e) { // move on touch
        if (moved) return moved = false;
        var t = e.originalEvent.changedTouches.item(0);
        me.goTo(new nko.Vector(t.pageX, t.pageY));
      })

    // #foo links: walk to, then warp there
    /*
    $('a[href^="#"]').live('click', function(e) {
      if ($(this).attr('href') === '#') return;
      e.preventDefault();
      var page = $($(this).attr('href'));
      setTimeout(function checkArrived() {
        if (me.div.queue().length === 0) {
          nko.warpTo(page);
          page.click();
        } else {
          setTimeout(checkArrived, 500);
        }
      }, 1);
    });
    */

    // chat
    var speakTimeout, $text = $('<textarea>')
      .appendTo($('<div class="textarea-container">')
      .appendTo(me.div))
      .bind('keyup', function(e) {
        var text = $text.val();
        switch (e.keyCode) {
          case 13:
            $text.val('');
            return false;
          default:
            me.speak(text);
            nko.send({
              obj: me,
              method: 'speak',
              arguments: [ text ]
            });
            clearTimeout(speakTimeout);
            speakTimeout = setTimeout(function() {
              $text.val('');
              me.speak();
              nko.send({
                obj: me,
                method: 'speak'
              });
            }, 5000);
        }
      }).focus();
    $(document).keylisten(function(e) {
      if (e.altKey || e.ctrlKey || e.metaKey) return true;
      switch (e.keyName) {
        case 'meta':
        case 'meta+ctrl':
        case 'ctrl':
        case 'alt':
        case 'shift':
        case 'up':
        case 'down':
        case 'left':
        case 'right':
          return;
        default:
          $text.focus()
      }
    });


    //// flare
    new nko.Thing({ name: 'streetlamp', pos: new nko.Vector(-10, 160) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(-80, 120) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(580, 80) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(1000, 380) });
    new nko.Thing({ name: 'deadtree', pos: new nko.Vector(1050, 420) });

    //// lounge
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(-60, 870) });
    new nko.Thing({ name: 'deadtree', pos: new nko.Vector(0, 900) });
    new nko.Thing({ name: 'portopotty', pos: new nko.Vector(80, 900) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(550, 1050) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(500, 1250) });
    new nko.Thing({ name: 'deadtree', pos: new nko.Vector(560, 1300) });
    new nko.Thing({ name: 'desk', pos: new nko.Vector(500, 1350) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(120, 1800) });
    new nko.Thing({ name: 'deadtree', pos: new nko.Vector(70, 1700) });
    new nko.Thing({ name: 'livetree', pos: new nko.Vector(-10, 1900) });
  });

  nko.Bubble = [
    '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'
  ];
})(nko); // export nko
