app = require '../config/app'
_ = require 'underscore'
m = require './middleware'
Vote = app.db.model 'Vote'
Team = app.db.model 'Team'

ensureVoting = (req, res, next) ->
  return next() if req.user?.admin
  if app.enabled 'voting' then next() else next 401

loadVoteTeam = (req, res, next) ->
  return next() if not req.vote or req.vote.team
  Team.findById req.vote.teamId, (err, team) ->
    return next err if err
    req.vote.team = team
    next()

buildVote = (req) ->
  attr = _.clone req.body
  attr.audit?.remoteAddress = req.socket.remoteAddress
  attr.audit?.remotePort = req.socket.remotePort
  _.extend attr,
    personId: req.user.id
    teamId: req.team.id
    type: req.user.role
  vote = new Vote attr

# create
app.post '/teams/:teamId/votes', [ensureVoting, m.ensureAuth, m.loadTeam], (req, res, next) ->
  # team members may not vote on their own teams
  return next 401 if req.user and req.team.includes(req.user)
  vote = buildVote req
  vote.save (err) ->
    return next err if err
    res.redirect 'back'
    if req.user.judge or req.user.contestant
      req.team.voteCounts[req.user.role].increment()
      req.team.save()

# create - iframe
app.post '/teams/:teamId/votes.iframe', [m.loadTeam], (req, res, next) ->
  return res.send 401 unless req.user?.voter
  vote = buildVote req
  vote.save (err) ->
    res.send 500 if err
    res.send vote.id, 200

# update
app.put '/votes/:id', [ensureVoting, m.loadVote, m.ensureAccess], (req, res, next) ->
  delete req.body[attr] for attr in ['personId', 'teamId', 'type']
  _.extend req.vote, req.body
  req.vote.save (err) ->
    return next err if err
    res.redirect 'back'

# reply
app.post '/votes/:id/replies', [ensureVoting, m.loadVote, loadVoteTeam], (req, res, next) ->
  debugger
  return next 401 unless req.vote.replyable req.user
  reply = new Vote.Reply
  _.extend reply,
    personId: req.user.id
    message: req.body.message

  req.vote.replies.push reply
  req.vote.save (err) ->
    return next err if err
    res.redirect 'back'

# delete
app.delete '/votes/:id', [ensureVoting, m.loadVote, m.ensureAccess], (req, res, next) ->
  req.vote.remove (err) ->
    return next err if err
    res.redirect 'back'

# delete - iframe
app.delete '/votes/:id.iframe', [m.loadVote], (req, res, next) ->
  return res.send 401 unless req.user?.id is req.vote.id
  req.vote.remove (err) ->
    return next err if err
    res.send 200
