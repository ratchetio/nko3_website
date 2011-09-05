app = require '../config/app'
Vote = app.db.model 'Vote'
m = require './middleware'

app.get '/iframe/:teamId', [m.loadTeam, m.loadMyVote], (req, res) ->
  css = req.query.css if /^https?:\/\//.test(req.query.css) and not /\.htc$/.test(req.query.css)
  req.vote = null unless req.user?.voter
  Vote.count teamId: req.team._id, type: 'voter', (err, count) ->
    next err if err
    res.header 'Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0'
    res.header 'Expires', 'Fri, 31 Dec 1998 12:00:00 GMT'
    res.header 'Pragma', 'no-cache'
    res.render 'iframe', layout: false, vote: req.vote, count: count, css: css

app.get '/iframe/:teamId/authed', [m.loadTeam, m.loadMyVote], (req, res) ->
  res.render 'iframe/authed', layout: false, vote: req.vote

app.get '/iframe/:teamId/test', (req, res) ->
  res.render 'iframe/test', layout: false
